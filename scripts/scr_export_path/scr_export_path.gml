/// @function              
/// @description             
/// @param {Id.Instance}     
/// @param {Asset.GMObject}  
/// @return {Bool}
function PathExport(_path){

	var _stringy = json_stringify(_path)
	var _pre = "{ \"$GMPath\":\"\",  \"%Name\":\"Path1\",  \"closed\":false,  \"kind\":0,  \"name\":\"Path1\",  \"parent\":{    \"name\":\"Paths\",    \"path\":\"folders/Paths.yy\",  },\"points\":"
	var _post = ",  \"precision\":8,  \"resourceType\":\"GMPath\",  \"resourceVersion\":\"2.0\",}"
	_stringy = array_concat(_pre,_stringy,_post)
	var _buff = buffer_create(string_byte_length(_stringy), buffer_fixed, 1);
	
	
	buffer_write(_buff, buffer_text, _stringy);
	buffer_save(_buff, "path_here.yy");
	buffer_delete(_buff);

}