---
config:
  layout: elk
---
erDiagram
    USERS ||--o{ CUSTOMERS : has_profile
    CUSTOMERS ||--o{ RESERVATIONS : makes
    VEHICLES ||--o{ RESERVATIONS : is_booked_in
    RESERVATIONS ||--o| PAYMENTS : generates
    RESERVATIONS ||--o| REVIEWS : receives
    RESERVATIONS ||--o{ DISPUTES : may_have

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
    }