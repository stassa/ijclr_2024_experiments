library(r.oguelike)

# Doesn't work and keeps generating the same dungeon in a loop k times.
gen <- function(k=10) {

	for (i in 1:k) {
	
		m <- r.oguelike::generate_dungeon(
		  iterations = 5,
		  n_row = 20,
		  n_col = 20,
		  n_rooms = 5,
		  is_snake = FALSE,
		  is_organic = TRUE,
		  seed = NULL,
		  colour = TRUE
		)

		dungeon.file <- paste("dungeon_", i, ".map",sep="")

		write.table(m,  file = dungeon.file, quote = FALSE, sep =" " ,row.names = FALSE, col.names = FALSE)
		m <- ''
	}


}

#gen(1)

gen <- function(name,row=20,col=20,rooms=5) {
	
	m <- r.oguelike::generate_dungeon(
	  iterations = 5,
	  n_row = row,
	  n_col = col,
	  n_rooms = rooms,
	  is_snake = FALSE,
	  is_organic = TRUE,
	  seed = NULL,
	  colour = TRUE
	)

	dungeon.file <- paste("dungeon_", name, ".map",sep="")

	write.table(m,  file = dungeon.file, quote = FALSE, sep =" " ,row.names = FALSE, col.names = FALSE)
	m <- ''
	}

#gen("small",12,12,5)
