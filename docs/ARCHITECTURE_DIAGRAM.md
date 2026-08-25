# Meal Clarity - Architecture & AI Accuracy Flow

This document details the end-to-end architecture and the AI accuracy flow for the Meal Clarity application, explicitly showing how hallucinations are prevented and how the "Model interprets, Catalog decides" philosophy is implemented.

```mermaid
flowchart TB
    %% --- Colors & Styles ---
    classDef frontend fill:#E3F2FD,stroke:#1565C0,stroke-width:2px,color:#000
    classDef backend fill:#F3E5F5,stroke:#7B1FA2,stroke-width:2px,color:#000
    classDef llm fill:#FFF8E1,stroke:#F57F17,stroke-width:2px,color:#000
    classDef db fill:#E8F5E9,stroke:#2E7D32,stroke-width:2px,color:#000
    classDef admin fill:#FFF3E0,stroke:#E65100,stroke-width:2px,color:#000
    classDef logic fill:#FAFAFA,stroke:#424242,stroke-width:1px,color:#000
    classDef critical fill:#FFEBEE,stroke:#C62828,stroke-width:2px,color:#000,stroke-dasharray: 5 5

    %% --- Frontend (Flutter) ---
    subgraph Client ["Frontend (Flutter App)"]
        direction TB
        InputText[("✍️ Text Input\n(e.g., '2 yumurta yedim')")]:::frontend
        InputPhoto[("📸 Photo Input")]:::frontend
        
        UI_Clarification["❓ Clarification UI\n(Asks Type or Amount)"]:::frontend
        UI_Manual["🔍 Manual Search / Correction"]:::frontend
        UI_Estimate["⚠️ AI Estimate Indicator\n(For Out-of-Catalog)"]:::frontend
        UI_Success["✅ Logged Meal"]:::frontend
    end

    %% --- Backend (Node.js) ---
    subgraph API ["Backend (Node.js / Express)"]
        direction TB
        Auth["🔒 Auth & Rate Limiting\n(Supabase Middleware)"]:::logic
        
        subgraph Extraction ["1. Entity Extraction Phase"]
            direction TB
            Parser["⚡ Deterministic Parser\n(Fast Path)"]:::logic
            LLM_Extract["🧠 LLM Extraction (OpenAI)\nStrict Schema: [Identity, Amount] ONLY\nNO Nutrition Allowed"]:::llm
        end
        
        subgraph Retrieval ["2. Retrieval Phase (Concurrent)"]
            direction LR
            R_Exact["🎯 Exact Alias Match"]:::logic
            R_FTS["🔍 Full-Text / Trigram"]:::logic
            R_Vector["📉 PgVector Similarity\n(OpenAI Embeddings)"]:::logic
        end
        
        RRF["🧮 Reciprocal Rank Fusion (RRF)"]:::logic
        
        LLM_Select["🎯 Strict-Schema LLM Selection\n(Picks best match from allowed IDs)"]:::llm
        
        subgraph Resolution ["3. Resolution & Confidence Engine"]
            direction TB
            Check_Threshold{"Confidence\n> Threshold?"}:::logic
            Check_Ambiguity{"Is Ambiguous?\n(Generic ID or No Portion)"}:::logic
            Check_Estimate{"Is completely\nout of catalog?"}:::logic
            
            Action_Clarify["Trigger: checkAmount / checkType"]:::logic
            Action_NoMatch["Trigger: NO_MATCH"]:::logic
            Action_Estimate["Generate AI Estimate\n(Saved as unreviewed)"]:::logic
            Action_Commit["Idempotent Commit"]:::logic
        end
        
        Telemetry["📊 Telemetry & Eval Logger\n(Logs tokens, latency, cost, diffs)"]:::backend
    end

    %% --- Database (Supabase) ---
    subgraph Database ["Postgres Database (Supabase)"]
        direction TB
        Catalog[("🗄️ 60k Food Catalog\n(USDA & TürKomp)\n[Immutable Truth]")]:::db
        MealLogs[("🥗 User Meal Logs\n(RLS Enforced)")]:::db
        EvalData[("📈 Eval Runs & Telemetry")]:::db
    end

    %% --- Admin Dashboard ---
    subgraph Admin ["Internal Tools (React)"]
        direction TB
        Admin_Evals["📊 AI Quality & Evals Viewer"]:::admin
        Admin_Catalog["🔎 Catalog Inspector"]:::admin
    end

    %% --- Edges & Relationships ---
    
    %% Input flow
    InputText --> Auth
    InputPhoto --> Auth
    
    %% Extraction flow
    Auth --> Parser
    Parser -- "If parsing fails" --> LLM_Extract
    Parser -- "Parsed Entities" --> R_Exact
    LLM_Extract -- "Extracted Entities" --> R_Exact
    
    %% Retrieval Flow
    R_Exact & R_FTS & R_Vector --> RRF
    RRF --> LLM_Select
    
    %% DB lookups during retrieval
    Catalog -. "Provides Candidates" .-> R_Exact
    Catalog -. "Provides Candidates" .-> R_FTS
    Catalog -. "Provides Embeddings" .-> R_Vector
    
    %% Selection & Resolution
    LLM_Select --> Check_Threshold
    Check_Threshold -- "Yes" --> Check_Ambiguity
    Check_Threshold -- "No" --> Check_Estimate
    
    Check_Estimate -- "Yes (Complex Dish)" --> Action_Estimate
    Check_Estimate -- "No (Garbage input)" --> Action_NoMatch
    
    Check_Ambiguity -- "Yes (Needs details)" --> Action_Clarify
    Check_Ambiguity -- "No (Perfect Match)" --> Action_Commit
    
    %% Nutrition Grounding (CRITICAL PATH)
    Action_Commit =="CRITICAL:\nReads True Calories"==> Catalog
    Action_Commit --> MealLogs
    
    %% Back to Frontend
    Action_Clarify --> UI_Clarification
    Action_NoMatch --> UI_Manual
    Action_Estimate --> UI_Estimate
    UI_Estimate --> MealLogs
    
    UI_Clarification -- "User provides detail" --> Action_Commit
    UI_Manual -- "User finds food" --> Action_Commit
    Action_Commit --> UI_Success
    
    %% Telemetry & Admin
    LLM_Extract & LLM_Select & Action_Commit --> Telemetry
    Telemetry --> EvalData
    EvalData --> Admin_Evals
    Catalog --> Admin_Catalog
```

## Key Architectural Decisions Highlighted

1. **Schema Restriction (Entity Extraction):** The extraction LLM is physically incapable of returning nutrition data. It can only return `Identity` and `Amount`.
2. **Tri-modal Retrieval:** We don't rely solely on vector search. We use Exact Matches, Trigrams, and Vectors combined via RRF to ensure we find the right catalog rows.
3. **The "Critical Path" (Red Dashed Arrow):** Even if the LLM is confident, the final numbers are **always** read directly from the `Catalog` inside Postgres during the commit. The client/LLM can never forge a calorie count.
4. **Clarification Loop:** Instead of guessing when a generic term (e.g., "Egg") is used, the system halts and asks the user (Clarification UI), fixing the biggest issue with competitor apps (portion inaccuracy).
