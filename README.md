#Pyramid Chess

This involves developing a 2D game using the Godot video game engine, which is a variant of chess (mainly aimed at children) designed to help them understand the value of the pieces using a language based on the basic rules of arithmetic and algebra, and to learn these rules at the same time through the combination of operations such as addition, subtraction, multiplication, division, exponentiation, and root extraction in a playful context.

##Tech Stack
* **Engine:** Godot Engine (GDScript)
* **Art:** Piskel (Pixel Art)
* **Music and Sound:** LMMS
* **Version Control:** Git and GitHub

##Project objective
To help more people discover and understand the world of chess and mathematical arithmetic in a dynamic and fun way, especially for children.


##How theb Game works
The main idea of ​​the game is that it can be played by two people using the same keyboard. Character 1 is the white knight, whose objective is to capture the black pieces (the opposing color). Character 2, also the black knight, has the same objective, but must capture the white pieces. Movement between the characters is simple: Character 1 moves with the arrow keys, and Character 2 moves with the WASD key. It's important to note that characters can move diagonally by combining the keys, but they cannot move backward on the board. The main objective of the game is to reach the last rank where the king is located and capture it. The pieces move horizontally, and when an opposing piece is captured, the knight automatically moves at the same rate as the other pieces on that rank. Pieces on even-numbered ranks move to the left, and those on odd-numbered ranks move to the right. If a piece of the same color is accidentally captured, the rider automatically moves back one square.

##Scores Rules
There is a scoring system for the different players (player 1 and player 2, who start with 100 points). If a player captures a pawn of the opposite color, they automatically gain 1 point; otherwise (if they capture a pawn of the same color as the knight), they lose 1 point. This same logic applies to the other pieces, but with different mathematical operations. For the knight rank, if a knight of the opposite color is captured, the number of points is multiplied by 2, and otherwise (capturing a knight of the same color as the knight), the points are divided by 2. The same applies to the bishop rank, except now the points are multiplied by 3 and divided by 3. For the rook rank, the points are either squared or the square root is applied. For the queen rank, the points are either cubed or the cube root is applied.
