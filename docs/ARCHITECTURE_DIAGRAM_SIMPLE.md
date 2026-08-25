# Meal Clarity - Core Architecture Flow

This diagram illustrates the core technical flow, showing how inputs are processed through deterministic parsers, vector embeddings, and LLM selection, while strictly isolating nutrition facts in the database.

```mermaid
flowchart TD
    %% --- Colors ---
    classDef user fill:#E3F2FD,stroke:#1565C0,stroke-width:2px,color:#000
    classDef ai fill:#FFF8E1,stroke:#F57F17,stroke-width:2px,color:#000
    classDef search fill:#F3E5F5,stroke:#7B1FA2,stroke-width:2px,color:#000
    classDef db fill:#E8F5E9,stroke:#2E7D32,stroke-width:2px,color:#000

    %% --- Nodes ---
    Input(("User Input\n(Text / Photo)")):::user
    
    subgraph Extraction ["1. Extraction"]
        Regex["⚡ Deterministic Regex Parser"]:::search
        LLM_Extract["🧠 OpenAI LLM Extractor\n(Fallback: Extracts Identity & Amount)"]:::ai
    end
    
    subgraph Retrieval ["2. Search & Retrieval"]
        Vector["📉 PgVector Search\n(OpenAI Embeddings)"]:::search
        FTS["🔍 Full-Text / Trigram"]:::search
        RRF["🧮 Reciprocal Rank Fusion (RRF)"]:::search
    end
    
    Select["🎯 LLM Candidate Selection\n(Strict Schema from allowed IDs)"]:::ai
    
    Clarify{"Needs Detail?\n(Which Type/Gram?)"}:::search
    AskUser["❓ User Clarification UI"]:::user
    
    Save["✅ Save to Postgres DB\n(Nutrition read directly from Catalog)"]:::db

    %% --- Edges ---
    Input --> Regex
    Regex -. "If parsing fails" .-> LLM_Extract
    
    Regex --> Vector & FTS
    LLM_Extract --> Vector & FTS
    
    Vector & FTS --> RRF
    RRF --> Select
    
    Select --> Clarify
    Clarify -- "Yes" --> AskUser
    AskUser --> Save
    Clarify -- "No" --> Save
```
