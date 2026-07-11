---
config:
  layout: elk
---
erDiagram
    USERS ||--o| AGENCIES : manages
    AGENCIES ||--o{ AGENCY_VERIFICATIONS : has
    AGENCIES ||--o{ BRANCHES : operates
    BRANCHES ||--o{ EMPLOYEES : employs
    AGENCIES ||--o{ VEHICLES : owns
    BRANCHES ||--o{ VEHICLES : assigns

    USERS {
        uuid user_id PK
        string full_name
        string email
        string password_hash
        string phone_number
        enum role
        enum account_status
    }

    AGENCIES {
        uuid agency_id PK
        uuid user_id FK
        string agency_name
        string business_license
        enum verification_status
        text description
    }

    AGENCY_VERIFICATIONS {
        uuid verification_id PK
        uuid agency_id FK
        string verified_by
        text verification_notes
        timestamp verified_at
    }

    BRANCHES {
        uuid branch_id PK
        uuid agency_id FK
        string branch_name
        text address
        string city
        string phone
    }

    EMPLOYEES {
        uuid employee_id PK
        uuid branch_id FK
        string full_name
        string position
        string email
        string phone
    }

    VEHICLES {
        uuid vehicle_id PK
        uuid agency_id FK
        uuid branch_id FK
        string brand
        string model
        int year
        string fuel_type
        string transmission
        string plate_number
        decimal price_per_day
        enum status
    }