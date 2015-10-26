{{GLSL_VERSION}}

{{vertex_type}} vertex;
in float lastlen;
//in float thickness;
{{color_type}} color;

uniform mat4 projectionview, model;
uniform uint objectid;

flat out uvec2 g_id;
out vec4 g_color;
out float g_lastlen;
out float g_thickness;

vec4 getindex(sampler2D tex, int index);
vec4 getindex(sampler1D tex, int index);

vec4 to_vec4(vec3 v)
{
	return vec4(v, 1);
}
vec4 to_vec4(vec2 v)
{
	return vec4(v, 0, 1);
}
void main()
{
	g_lastlen 	= lastlen;
	int index 	= gl_VertexID;
	g_id 		= uvec2(objectid, index+1);
	//g_thickness = thickness;
	g_color 	= {{color_calculation}};
	gl_Position = projectionview*model*to_vec4(vertex);
}