#heading(level: 1, [Main Title])

 #label("index.md#Main-Title")


This is a paragraph with #strong([bold]) and #emph([italic]).



#heading(level: 2, [Subsection])

 #label("index.md#Subsection")



- List item 1
- List item 2




#raw("code_example()", block: true, lang: "julia")


#align(center)[
#table(
columns: (1fr,1fr,),
align: (x, y) => (right,right,).at(x),
 [Col1], [Col2],
 [A], [B],
)]