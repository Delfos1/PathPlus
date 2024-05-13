/// @description Transforms a path into a PathPlus with Catmull-Rom interpolation

pathplus = new PathPlus(Path1) 
pathplus.PathFlip().PathRotate(10)
pathplus.SetBezier()
pathplus.BakeToPath()
