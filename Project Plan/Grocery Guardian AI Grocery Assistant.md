## Grocery Guardian: AI Grocery Assistant

#### Project Objectives

Grocery Guardian is a practical tool designed to help users identify allergens in grocery and cosmetic products. Many people find it hard to understand ingredient lists, especially when allergens are hidden under unfamiliar names. This can lead to health risks and poor purchasing decisions. Users also lack easy ways to track their grocery habits or monitor things like sugar intake.

Our goal is to create a simple and effective system where users can scan a product barcode to see its ingredients, get alerts if allergens are present, and receive suggestions for safer alternatives. Users can also upload receipts to keep track of what they’ve bought and review their nutrition trends over time.

The app allows users to set their dietary restrictions, such as specific allergens or sugar limits, so that feedback and suggestions are personalized. We also plan to explore a reward feature using blockchain to encourage users to buy more sustainable or healthier products.

By combining barcode scanning, ingredient analysis, receipt tracking, and user preferences, this project aims to help people make safer and smarter decisions when shopping.


#### Architecture

Our system architecture follows a modular, cloud-assisted web application structure composed of a frontend, backend, and integrated Azure services.

1- Frontend: A lightweight web interface developed using HTML/CSS/JavaScript (or React), allowing users to scan barcodes, view ingredient lists, receive allergen alerts, and explore recommended alternatives. Barcode images will be captured and uploaded through the web UI.

2-Backend: A RESTful API service implemented with Spring Boot, deployed locally in early stages and later containerized for Azure deployment. It handles user account management (login, preferences), product queries, and coordinates with external AI services (OCR & NLP).

3-Cloud Services(Azure):

    (1)-Azure SQL Database stores user profiles, scanned product data, ingredient tags, and allergy mappings.
    (2)-Azure Computer Vision API is called to perform Optical Character Recognition (OCR) on product packaging and receipts.
    (3)-Azure AI Services / OpenAI GPT via Azure will assist in NLP-based allergen analysis and dietary recommendation logic.

4-Inter-service communication: The backend will orchestrate API calls to Azure services and manage the data flow between the user interface and cloud AI results. Requests are processed asynchronously where necessary (e.g., OCR + NLP response).

5-Deployment Considerations: We plan to use **Azure App Service** or containerized deployment (Docker) for the backend in the later phase, to ensure maintainability and scalability. Azure portal credentials and deployment evidence will be included in the final documentation.

```
                                        [ Web Frontend: User Login, User Register, User preference, Barcode Scanning]
                                                                          |
                                                            (upload image or barcode data)
                                                                          |
                             [ Backend API (Spring Boot): Handle user session, route OCR/NLP requests, return analysis results]
                                                                          |
 |────────────────────────────────────────────────────────────────────────|───────────────────────────────────────────────────────────|
 |                                                                        |                                                           |
OCR API                                                             NLP (Azure GPT)                                               Azure SQL
(Azure CV):                                                         (Allergen Logic)                                         (User + Product DB)
Extract text from image                                             Detect allergens,                                        Store user profile,
or barcode                                                          generate safe                                            preferences, scan history,
using Computer Vision                                               food suggestions                                         product information
```
