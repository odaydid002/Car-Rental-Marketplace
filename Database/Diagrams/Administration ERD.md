---
config:
  layout: elk
---
erDiagram
    USERS ||--o{ NOTIFICATIONS : receives
    USERS ||--o{ ANALYTICS_REPORTS : generates
    USERS ||--o{ DISPUTES : submits
    CUSTOMERS ||--o{ AI_RECOMMENDATIONS : receives
    CUSTOMERS ||--o{ AI_CONVERSATIONS : has
    RESERVATIONS ||--o{ DISPUTES : has

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

    RESERVATIONS {
        uuid reservation_id PK
        uuid customer_id FK
        uuid vehicle_id FK
        date pickup_date
        date return_date
        decimal total_price
        enum reservation_status
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
