# Two Dots — Web Game Implementation

A university group project developed for **Logic for Computer Science (2026)** at the **Universidad Nacional del Sur (UNS)**, Department of Computer Science and Engineering (DCIC), Argentina.

This project is a web-based implementation of *Two Dots*, a color-matching puzzle game in which players connect adjacent dots of the same color to clear the board, trigger gravity, and complete level-specific objectives.

The application is based on a starter implementation provided by the course instructors, combining **Prolog** for game logic and **React** for the user interface.

![Two Dots — Original Game Screenshot](docs/images/2dots-game-screenshot.png)

*Reference image of the original Two Dots game.*

Original game: [Two Dots](https://www.twodots-game.com/game)

---

## About the Project

The project was developed as part of the practical coursework for Logic for Computer Science. The assignment consisted of extending a starter repository built with React and Prolog to implement the main mechanics of Two Dots.

The original course specification established the functional requirements, the initial project structure, and the division of responsibilities between the frontend and backend.

Our team worked collaboratively on extending and adapting this foundation, focusing on the implementation of the assigned game mechanics and the integration between the two technologies.

The repository represents the team's actual development work. Not every feature or mechanic from the original game, or every requirement described in the assignment, should be interpreted as fully implemented.

## Technologies

- **Prolog (SWI-Prolog):** Declarative programming and game logic.
- **React:** User interface and interactive components.
- **JavaScript / TypeScript:** Frontend functionality and application logic.
- **Pengines:** Communication between the React application and the Prolog backend.
- **CSS:** Interface styling and visual presentation.
- **Git & GitHub:** Version control and collaborative development.

## Game Concept and Functional Requirements

The assignment was based on reproducing the main mechanics of Two Dots in a web application.

The original specification included the following requirements:

- **Color Matching:** Select and connect adjacent dots of the same color to make valid moves.
- **Gravity and Tile Generation:** After removing dots, the remaining elements fall to fill available spaces, and new dots are generated at the top of the board.
- **Level Objectives:** Track the number of dots removed for each required color and display the player's progress.
- **Closed Loops:** Detect closed paths formed by dots of the same color and remove all dots of that color from the board.
- **Bomb Creation:** Convert elements enclosed by a closed loop into bombs.
- **Bomb Explosions:** Exploding bombs remove elements within a 3×3 area centered on their position.
- **Obstacles and Empty Spaces:** Handle special cells that cannot contain dots and affect gravity.
- **Water Mechanics:** Allow water to spread to neighboring cells when adjacent dots are removed, potentially becoming a level objective.
- **Game Completion:** Detect victory when the level objectives are achieved and defeat when no valid moves remain.

These items describe the functional scope established by the course assignment, rather than a claim that every mechanic was completed in the submitted implementation.

## Architecture

The application follows a client-server architecture, separating the game logic from its visual representation.

### Prolog — Game Logic

The backend is implemented in SWI-Prolog and is responsible for the declarative side of the game.

The starter project establishes the main game interface through the `connect/4` predicate, which is called by the React frontend.

The original project also defines the initial board configuration and level objectives in `init.pl`.

Main files:

- `pengines_server/apps/proylcc/init.pl` — Initial game configuration, board representation, and objectives.
- `pengines_server/apps/proylcc/proylcc.pl` — Prolog game logic and the `connect/4` predicate.

### React — User Interface

The frontend is responsible for the visual and interactive aspects of the application, including:

- Rendering the game board and its elements.
- Handling player selections and interactions.
- Displaying game objectives and progress.
- Presenting game states and visual feedback.

### Frontend–Backend Communication

The application uses **Pengines** to connect React with the SWI-Prolog server, allowing the frontend to request game operations and receive their results.

This integration combines declarative problem-solving in Prolog with an interactive web interface.

## Running the Project Locally

### Requirements

- [Node.js](https://nodejs.org/en/)
- [SWI-Prolog](https://www.swi-prolog.org/Download.html)
- npm

### 1. Clone the Repository

```bash
git clone https://github.com/MariaVictoriaGit/two-dots-uns-2026.git
cd two-dots-uns-2026
```

### 2. Install Dependencies

```bash
npm install
```

### 3. Start the Prolog Server

Open a terminal in the project directory and run:

```bash
npm run pengines
```

The first execution may request a username and password for the SWI-Prolog web administration console.

The Prolog server will be available at:

`http://localhost:3030`

**Note:** Whenever Prolog source files are modified, restart the Pengines server to apply the changes.

### 4. Start the React Application

Open a second terminal in the project directory and run:

```bash
npm run dev
```

The application will be available at:

`http://localhost:3000`

The development server automatically refreshes the application when frontend source files change.

**Both servers must be running simultaneously for the application to work correctly.**

## Project Structure

```text
two-dots-uns-2026/
│
├── README.md                 # English — presentation and documentation
├── README-original.md        # Original course assignment (Spanish)
│
├── docs/
│   ├── images/
│   │   └── 2dots-game-screenshot.png
│   └── INFORME.md            # Original team project report
│
├── pengines_server/
├── src/
└── package.json
```

*The structure above is illustrative. Additional files and directories are included in the repository.*

## Contributors

Developed collaboratively by:

- **[Laura Arboleas](https://github.com/laura-arboleas)**
- **[María Victoria](https://github.com/MariaVictoriaGit)**
- **[Ciberocio](https://github.com/ciberocio)**

This was a collaborative academic project, with contributions from all three team members throughout its development.

## Academic Context and Credits

**Institution:** Universidad Nacional del Sur (UNS), Argentina  
**Department:** Department of Computer Science and Engineering (DCIC)  
**Course:** Logic for Computer Science (Lógica para Ciencias de la Computación)  
**Academic Year:** 2026  
**Project:** Two Dots — React + Prolog

The project was based on the starter implementation and functional specification provided by the course instructors.

**Original course repository:**

[ LCC-DCIC-UNS-2026 / proyecto-two-dots-com-6 ](https://github.com/LCC-DCIC-UNS-2026/proyecto-two-dots-com-6)

The original repository provided the initial React and Prolog implementation, development environment, and assignment requirements.

This repository preserves the development history of the team's work and acknowledges the original academic context and all collaborators.

---

**Project type:** University coursework · Collaborative software project  
**Year:** 2026  
**Main technologies:** Prolog · React · JavaScript · Pengines