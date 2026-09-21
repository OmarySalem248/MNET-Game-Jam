shader_type canvas_item;

uniform float t;
const float f= 5.0;
uniform bool dir = false;
uniform sampler2D noise;


void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	if (texture(noise,vec2(((float(int(UV.x*30.0)))/300.0),UV.y/10.0)).r < t){
		COLOR.a = 1.0;
	}
	else{
		COLOR.a = 0.0;
	}

	// Called for every pixel the material is visible on.
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
