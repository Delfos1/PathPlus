// Create an empty PathPlus

var pathplus = new PathPlus();

// Import the .pp PathPlus file from Included Files

pathplus.Import("path.pp")

// Manipulate further

pathplus.Simplify()

// Bake into a GMpath

GMPath = path_duplicate(pathplus.BakeToPath())

//Destroy the PathPlus
pathplus.Destroy()

//GMPath still exists and can be used as a regular path