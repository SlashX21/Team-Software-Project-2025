## Grocery Guardian: AI Grocery Assistant

#### Project Objectives

Grocery Guardian is a practical tool designed to help users identify allergens in grocery and cosmetic products. Many people find it hard to understand ingredient lists, especially when allergens are hidden under unfamiliar names. This can lead to health risks and poor purchasing decisions. Users also lack easy ways to track their grocery habits or monitor things like sugar intake.

Our goal is to create a simple system where users can scan a product barcode to see its ingredients, get alerts if allergens are present, and receive safer alternative suggestions. Users can also upload receipts to track what they’ve bought and review nutrition trends over time.

Technically, the system will use Azure’s Computer Vision API for barcode and receipt image processing, and Natural Language Processing to analyze ingredient text and detect allergens. A lightweight backend will handle data matching and user profiles. We plan to use a small database of common products and ingredients, and optionally implement a blockchain-based point system to reward sustainable purchases.

By combining computer vision, NLP, and cloud-based processing, this project aims to support safer and more informed shopping for people with allergies or specific dietary needs.

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


#### Project Plan

| Week          | Activity                       | Deliverables   |
| ------------- | -------------------------------| --------------:|
| 2nd of June   | Project Plan                   | Project Plan   |
| 9th of June   | Core Modules Development       | 1st Prototype  |
| 16th of June  | Testing and Deployment         | 2nd Prototype  |
| 23rd of June  | Interim Presentation           | Slides         |
| 30th of June  | Update and changes             | 3rd version    |
| 7nd of July   | Update and Improvements        | 4th version    |
| 14nd of July  | Optional Module Implementation | 5th version    |
| 21nd of July  | Testing and Finalisation       | Final Version  |
| 28th of July  | Final Presentation Preparation | Slides         |
| 4th of Aug    | Changes and Report on Feedback | Report draft   |
| 11th of Aug   | Finalise of Report             | Finalise Report|
| 19th of Aug   | Submission                     | -              |

#### Project Roles

*Scrum Master*: 
* Clarence Chong Yu Zhan

*Team*: 
* YanHao Sun
* PeiZheng Tang
* XiLiang Liu
* Xiang Li
