extends MeshInstance


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

export (Mesh) var malha
export (Vector2) var latlong

var api = "https://api.opentopodata.org/v1/aster30m?locations="
#var api = "https://api.opentopodata.org/v1/etopo1?locations="
var resposta

# Called when the node enters the scene tree for the first time.
func _ready():
	print([1, 2, 3, 4, 5].slice(0, 3))
	print(_centro())
	_chunk()


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func _chunk():
	var cr = _centro()
	var escala = self.get_scale().x
	var inicio = cr -Vector2(1, 1)*escala
	var fim = cr +Vector2(1, 1)*escala
	var passo = (fim.x - inicio.x)/7.0
	var link = api
	var http_request = HTTPRequest.new()
	http_request.connect("request_completed", self, "_on_HTTPRequest_request_completed")
	add_child(http_request)
	for j in range(8):
		for i in range(8):
			link += "%f,%f|"%[j*passo+inicio.x,i*passo+inicio.y]
	link.erase(link.length()-1, 1)
	var tudOk = http_request.request(link)
	var vish = yield(http_request, "request_completed")
	while tudOk != 0:
		tudOk = http_request.request(link)
	print(resposta)
	var res = resposta['results']
	var vertices = []
	var normals  = PoolVector3Array()
	
	var modelo = malha.surface_get_arrays(0)
	for j in range(8):
		var v = range(j*8, j*8+8)
		for i in range(8):
			modelo[0][v[i]].y = res[v[i]]['elevation']/1024.0
			vertices.append(0.0)
			normals.append(Vector3.ZERO)
	for i in range(len(modelo[8])/3):
		var face = range(i*3, i*3+3)
		var i1 = modelo[8][face[0]]
		var i2 = modelo[8][face[1]]
		var i3 = modelo[8][face[2]]

		var v1 = modelo[0][i1]
		var v2 = modelo[0][i2]
		var v3 = modelo[0][i3]

		var a1 = (v2-v1).normalized()
		var a2 = (v3-v1).normalized()

		var n = a2.cross(a1)

		normals[i1] += n
		vertices[i1] += 1.0
		normals[i2] += n
		vertices[i2] += 1.0
		normals[i3] += n
		vertices[i3] += 1.0

	for i in range(len(vertices)):
		normals[i] /= vertices[i]
	print(normals[0])
	modelo[1] = normals
	print(modelo[1][0])
	
	var am = ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, modelo)
	self.mesh = am
#	var estatico = StaticBody.new()

func _on_HTTPRequest_request_completed( result, response_code, headers, body ):
	resposta = parse_json(body.get_string_from_utf8())
	

func _centro():
	var saida = Vector2()
	saida.x = self.get_translation().x + latlong.x
	saida.y = self.get_translation().z + latlong.y
	return saida
	
	
