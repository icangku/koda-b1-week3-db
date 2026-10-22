```mermaid
erDiagram
USERS ||--||WALLET: owns
TRANSACTION_CATEGORY ||--o{TRANSACTION:classifies
MERCHANT |o--o{ TRANSACTION : "is paid in"
USERS |o--o{TRANSACTION:"receives"
USERS ||--o{TRANSACTION:"sends"
USERS {
  string id PK
  string name
  string password
  string email
  string photo
  int pin
}
WALLET {
  string id PK
  string user_id FK "unique"
  decimal balance
  datetime updated_at
}
TRANSACTION{
  string id PK
  string sender_user_id FK
  string receiver_user_id FK
  string type
  decimal amount
  datetime created_at
  datetime updated_at
}
```
