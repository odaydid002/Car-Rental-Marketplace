---
config:
  layout: elk
---
erDiagram
    USERS ||--o| CUSTOMERS : has_profile
    USERS ||--o| AGENCIES : has_profile
    USERS ||--o{ NOTIFICATIONS : receives
    USERS ||--o{ ANALYTICS_REPORTS : generates

    AGENCIES ||--o{ AGENCY_VERIFICATIONS : has
    AGENCIES ||--o{ BRANCHES : operates
    BRANCHES ||--o{ EMPLOYEES : employs
    AGENCIES ||--o{ VEHICLES : owns
    BRANCHES ||--o{ VEHICLES : assigns

    CUSTOMERS ||--o{ RESERVATIONS : makes
    VEHICLES ||--o{ RESERVATIONS : is_booked_in
    RESERVATIONS ||--o| PAYMENTS : generates
    RESERVATIONS ||--o| REVIEWS : receives
    RESERVATIONS ||--o{ DISPUTES : may_have

    CUSTOMERS ||--o{ AI_RECOMMENDATIONS : receives
    CUSTOMERS ||--o{ AI_CONVERSATIONS : has

    USERS {
        uuid user_id PK
        string full_name
        string email
        string password_hash
        string phone_number
        enum role
        enum account_status
    }

    CUSTOMERS {
        uuid customer_id PK
        uuid user_id FK
        string driver_license
        date date_of_birth
        text address
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

    RESERVATIONS {
        uuid reservation_id PK
        uuid customer_id FK
        uuid vehicle_id FK
        date pickup_date
        date return_date
        decimal total_price
        enum reservation_status
    }

    PAYMENTS {
        uuid payment_id PK
        uuid reservation_id FK
        decimal amount
        string payment_method
        enum payment_status
        string transaction_reference
    }

    REVIEWS {
        uuid review_id PK
        uuid reservation_id FK
        uuid customer_id FK
        int rating
        text comment
        timestamp review_date
    }

    DISPUTES {
        uuid dispute_id PK
        uuid reservation_id FK
        uuid submitted_by FK
        text reason
        enum status
        text resolution
        timestamp created_at
        timestamp resolved_at
    }

    NOTIFICATIONS {
        uuid notification_id PK
        uuid user_id FK
        string title
        string message
        boolean is_read
        timestamp sent_at
    }

    ANALYTICS_REPORTS {
        uuid report_id PK
        uuid generated_by FK
        string report_name
        string report_type
        timestamp generated_at
        json report_data
    }

    AI_RECOMMENDATIONS {
        uuid recommendation_id PK
        uuid customer_id FK
        uuid vehicle_id FK
        decimal recommendation_score
        timestamp generated_at
    }

    AI_CONVERSATIONS {
        uuid conversation_id PK
        uuid customer_id FK
        text user_message
        text ai_response
        timestamp created_at
    }
