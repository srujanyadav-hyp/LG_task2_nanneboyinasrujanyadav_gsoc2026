# Liquid Galaxy Flutter Controller - GSoC 2026 Task 2

**Author:** Nanneboyina Srujan Yadav  
**Organization:** Liquid Galaxy Project  

##  Description
This Flutter application serves as a controller for a Liquid Galaxy (LG) Rig. It establishes an SSH/SFTP connection to the Liquid Galaxy Master machine and allows the user to send commands and KML files to visualize content on the rig.

This project was developed as part of the **Google Summer of Code (GSoC) 2026** selection tasks.

##  Features

### 1. SSH Connection Manager
- Allows users to input the Liquid Galaxy Master's **IP Address**, **Port**, **Username**, and **Password**.
- Establishes a secure connection using the SSH2 client.
- Provides visual feedback on connection status (Connected/Disconnected).

### 2. Display Logo (Slave Screen)
- **Action:** Sends the Liquid Galaxy logo (`lg_logo.png`) to the **Left-most Screen** (Slave).
- **Technical Logic:** - Uploads the image via SFTP to `/var/www/html/`.
  - Creates a KML file (`slave_3.kml`) in the synced `kml/` folder.
  - The Master automatically syncs this to the Slave screen, which displays the overlay immediately.

### 3. Display Pyramid (Master Screen)
- **Action:** Draws a 3D Green Pyramid around a specific location (Visakhapatnam).
- **Technical Logic:** - Generates the KML code for a `<Polygon>` shape.
  - Uploads the file as `pyramid.kml`.
  - Updates the `kmls.txt` "playlist" on the Master to instruct Google Earth to load this specific file.

##  Tech Stack
- **Framework:** Flutter (Dart)
- **Communication:** SSH & SFTP
- **Visualization:** KML (Keyhole Markup Language)

##  Installation & Setup

1. **Clone the Repository**
   ```bash
   git clone <your-repo-url>
   cd task2_nanneboyinasrujanyadav_gsoc2026