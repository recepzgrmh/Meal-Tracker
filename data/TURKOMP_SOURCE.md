# Source and Provenance

- Source: TürKomp / Ulusal Gıda Kompozisyon Veri Tabanı
- Source URL: https://turkomp.tarimorman.gov.tr
- Primary extraction source: dynamically discovered food-detail pages
- Discovery source: `/component_result-enerji-2`
- Data basis: per 100 g edible portion, as stated on each detail page
- Download timestamp: recorded per page in `data/raw/turkomp/manifest.json`

## Method and transformations

Pages are requested with a descriptive user agent, four workers, short jitter, retries and resumable local caching. Every HTML response is retained and SHA-256 hashed. Metadata and all rows under `#foodResultlist` are extracted with deterministic HTML rules. No LLM, inference, imputation, rounding or external nutrient database is used.

Unambiguous Turkish decimal commas are converted to JSON/CSV decimal numbers (`19,14` → `19.14`). The original average/minimum/maximum text and original unit are retained. Empty, dash, trace and inequality tokens are represented as numeric `null` and preserved in the corresponding `*_raw` field.

## Site notice

At download time, the footer identifies the database as © TürKomp / Ulusal Gıda Kompozisyon Veri Tabanı, “Tüm Hakları Saklıdır,” and states that unauthorized copying and distribution of the database content is prohibited. The official `/useofdata` page says, in summary:

- the material is openly accessible and free unless otherwise stated when used for personal information purposes;
- commercial use requires a separate agreement and may require payment through the authorized institute;
- data may not be used without identifying the source;
- non-commercial use is described as possible under listed conditions, including no unauthorized changes and a visible TürKomp attribution/link;
- the site gives no guarantee of accuracy or currency, reserves intellectual-property rights, and may change its terms.

The page also contains more specific wording and conditions that control over this summary. This repository is a local research snapshot requested by the user and is not published or uploaded. It does not grant reuse or redistribution rights; review https://turkomp.tarimorman.gov.tr/useofdata and contact the rights holder before reuse beyond local personal research.
