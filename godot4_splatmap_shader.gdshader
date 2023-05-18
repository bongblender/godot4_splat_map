shader_type spatial;
render_mode blend_mix, diffuse_toon, specular_toon;

uniform sampler2D splat_map;
uniform bool Roughness_switch = true;
uniform bool AO_switch = true;
uniform bool Metalic_switch = false;
uniform bool Normal_switch = false;

uniform vec3 uv_scale_base = vec3(10.00,10.00,1.00);
uniform sampler2D albedo_base: source_color;
uniform sampler2D roughness_base;  
uniform sampler2D AO_base;  
uniform sampler2D Metalic_base;  
uniform sampler2D Normal_base :hint_normal; 

uniform vec3 uv_scale_R = vec3(10.00,10.00,1.00);
uniform sampler2D albedo_r: source_color;
uniform sampler2D roughness_r;  
uniform sampler2D AO_r;  
uniform sampler2D Metalic_r;  
uniform sampler2D Normal_r :hint_normal; 

uniform vec3 uv_scale_G = vec3(10.00,10.00,1.00);
uniform sampler2D albedo_g: source_color;
uniform sampler2D roughness_g; 
uniform sampler2D AO_g; 
uniform sampler2D Metalic_g; 
uniform sampler2D Normal_g :hint_normal; 

uniform vec3 uv_scale_B = vec3(10.00,10.00,1.00);
uniform sampler2D albedo_b: source_color;
uniform sampler2D roughness_b; 
uniform sampler2D AO_b; 
uniform sampler2D Metalic_b; 
uniform sampler2D Normal_b :hint_normal; 

uniform vec3 uv_scale_alpha = vec3(10.00,10.00,1.00);
uniform sampler2D alpha_albedo: source_color;
uniform sampler2D alpha_roughness; 
uniform sampler2D alpha_AO; 
uniform sampler2D alpha_Metalic; 
uniform sampler2D alpha_Normal :hint_normal; 

vec4 hash4( vec2 p ) { return fract(sin(vec4( 1.0+dot(p,vec2(37.0,17.0)), 
                                              2.0+dot(p,vec2(11.0,47.0)),
                                              3.0+dot(p,vec2(41.0,29.0)),
                                              4.0+dot(p,vec2(23.0,31.0))))*103.0); }

vec4 textureNoTile( sampler2D samp, in vec2 uv )
{
    vec2 iuv = floor( uv );
    vec2 fuv = fract( uv );
	
    // generate per-tile transform
    vec4 ofa = hash4( iuv + vec2(0.0,0.0) );
    vec4 ofb = hash4( iuv + vec2(1.0,0.0) );
    vec4 ofc = hash4( iuv + vec2(0.0,1.0) );
    vec4 ofd = hash4( iuv + vec2(1.0,1.0) );
    
    vec2 ddx = dFdx( uv );
    vec2 ddy = dFdy( uv );

    // transform per-tile uvs
    ofa.zw = sign(ofa.zw-0.5);
    ofb.zw = sign(ofb.zw-0.5);
    ofc.zw = sign(ofc.zw-0.5);
    ofd.zw = sign(ofd.zw-0.5);
    
    // uv's, and derivarives (for correct mipmapping)
    vec2 uva = uv*ofa.zw + ofa.xy; vec2 ddxa = ddx*ofa.zw; vec2 ddya = ddy*ofa.zw;
    vec2 uvb = uv*ofb.zw + ofb.xy; vec2 ddxb = ddx*ofb.zw; vec2 ddyb = ddy*ofb.zw;
    vec2 uvc = uv*ofc.zw + ofc.xy; vec2 ddxc = ddx*ofc.zw; vec2 ddyc = ddy*ofc.zw;
    vec2 uvd = uv*ofd.zw + ofd.xy; vec2 ddxd = ddx*ofd.zw; vec2 ddyd = ddy*ofd.zw;
        
    // fetch and blend
    vec2 b = smoothstep(0.25,0.75,fuv);
    
    return mix( mix( textureGrad( samp, uva, ddxa, ddya ), 
                     textureGrad( samp, uvb, ddxb, ddyb ), b.x ), 
                mix( textureGrad( samp, uvc, ddxc, ddyc ),
                     textureGrad( samp, uvd, ddxd, ddyd ), b.x), b.y );
}

void fragment() {
	

	vec4 splat_map_output = texture(splat_map, UV);
	
	///////////////////////////////////////////////////////////////////
	///////////////////////////ONLY FOR ALBEDO ////////////////////////
	//splatmap component
	float x_component_albedo = splat_map_output.x;
	float y_component_albedo = splat_map_output.y;
	float z_component_albedo = splat_map_output.z;
	float w_component_albedo = splat_map_output.w;
	//albedo alpha
	vec3 scaled_uv_albedo = vec3(UV, 0.0) * uv_scale_alpha;
	vec4 alpha_output_albedo = textureNoTile(alpha_albedo, vec2(scaled_uv_albedo.xy));
	//albedo base
	vec3 scaled_uv_2_albedo = vec3(UV, 0.0) * uv_scale_base;
	vec4 albedo_base_output = textureNoTile(albedo_base, vec2(scaled_uv_2_albedo.xy));
	//albedo red
	vec3 scaled_uv_3_albedo = vec3(UV, 0.0) * uv_scale_R;
	vec4 albedo_r_output = textureNoTile(albedo_r, vec2(scaled_uv_3_albedo.xy));
	//albedo green
	vec3 scaled_uv_4_albedo = vec3(UV, 0.0) * uv_scale_G;
	vec4 albedo_g_output = textureNoTile(albedo_g, vec2(scaled_uv_4_albedo.xy));
	//albedo blue
	vec3 scaled_uv_5_albedo = vec3(UV, 0.0) * uv_scale_B;
	vec4 albedo_b_output = textureNoTile(albedo_b, vec2(scaled_uv_5_albedo.xy));
	//mixing operation
	vec3 mix_stage_one_albedo = mix(vec3(albedo_base_output.xyz), vec3(albedo_r_output.xyz), vec3(x_component_albedo));
	vec3 mix_stage_two_albedo = mix(mix_stage_one_albedo, vec3(albedo_g_output.xyz), vec3(y_component_albedo));
	vec3 mix_stage_three_albedo = mix(mix_stage_two_albedo, vec3(albedo_b_output.xyz), vec3(z_component_albedo));
	vec3 final_albedo_mix = mix(vec3(alpha_output_albedo.xyz), mix_stage_three_albedo, vec3(w_component_albedo));
	///////////////////////////////////////////////////////////////////
	///////////////////////////////////////////////////////////////////

	///////////////////////////////////////////////////////////////////
	///////////////////////////ONLY FOR ROUGHNESS////////////////////////
	//splatmap component
	float x_component_roughness = splat_map_output.x;
	float y_component_roughness = splat_map_output.y;
	float z_component_roughness = splat_map_output.z;
	float w_component_roughness = splat_map_output.w;
	//roughness alpha
	vec3 scaled_uv_roughness = vec3(UV, 0.0) * uv_scale_alpha;
	vec4 alpha_output_roughness = textureNoTile(alpha_roughness, vec2(scaled_uv_roughness.xy));
	//roughness base
	vec3 scaled_uv_2_roughness = vec3(UV, 0.0) * uv_scale_base;
	vec4 roughness_base_output = textureNoTile(roughness_base, vec2(scaled_uv_2_roughness.xy));
	//roughness red
	vec3 scaled_uv_3_roughness = vec3(UV, 0.0) * uv_scale_R;
	vec4 roughness_r_output = textureNoTile(roughness_r, vec2(scaled_uv_3_roughness.xy));
	//roughness green
	vec3 scaled_uv_4_roughness = vec3(UV, 0.0) * uv_scale_G;
	vec4 roughness_g_output = textureNoTile(roughness_g, vec2(scaled_uv_4_roughness.xy));
	//roughness blue
	vec3 scaled_uv_5_roughness = vec3(UV, 0.0) * uv_scale_B;
	vec4 roughness_b_output = textureNoTile(roughness_b, vec2(scaled_uv_5_roughness.xy));
	//mixing operation
	vec3 mix_stage_one_roughness = mix(vec3(roughness_base_output.xyz), vec3(roughness_r_output.xyz), vec3(x_component_roughness));
	vec3 mix_stage_two_roughness = mix(mix_stage_one_roughness, vec3(roughness_g_output.xyz), vec3(y_component_roughness));
	vec3 mix_stage_three_roughness = mix(mix_stage_two_roughness, vec3(roughness_b_output.xyz), vec3(z_component_roughness));
	vec3 final_roughness_mix = mix(vec3(alpha_output_roughness.xyz), mix_stage_three_roughness, vec3(w_component_roughness));
	///////////////////////////////////////////////////////////////////
	///////////////////////////////////////////////////////////////////
	
	///////////////////////////////////////////////////////////////////
	///////////////////////////ONLY FOR AO ////////////////////////
	//splatmap component
	float x_component_AO = splat_map_output.x;
	float y_component_AO = splat_map_output.y;
	float z_component_AO = splat_map_output.z;
	float w_component_AO = splat_map_output.w;
	//AO alpha
	vec3 scaled_uv_AO = vec3(UV, 0.0) * uv_scale_alpha;
	vec4 alpha_output_AO = textureNoTile(alpha_AO, vec2(scaled_uv_AO.xy));
	//AO base
	vec3 scaled_uv_2_AO = vec3(UV, 0.0) * uv_scale_base;
	vec4 AO_base_output = textureNoTile(AO_base, vec2(scaled_uv_2_AO.xy));
	//AO red
	vec3 scaled_uv_3_AO = vec3(UV, 0.0) * uv_scale_R;
	vec4 AO_r_output = textureNoTile(AO_r, vec2(scaled_uv_3_AO.xy));
	//AO green
	vec3 scaled_uv_4_AO = vec3(UV, 0.0) * uv_scale_G;
	vec4 AO_g_output = textureNoTile(AO_g, vec2(scaled_uv_4_AO.xy));
	//AO blue
	vec3 scaled_uv_5_AO = vec3(UV, 0.0) * uv_scale_B;
	vec4 AO_b_output = textureNoTile(AO_b, vec2(scaled_uv_5_AO.xy));
	//mixing operation
	vec3 mix_stage_one_AO = mix(vec3(AO_base_output.xyz), vec3(AO_r_output.xyz), vec3(x_component_AO));
	vec3 mix_stage_two_AO = mix(mix_stage_one_AO, vec3(AO_g_output.xyz), vec3(y_component_AO));
	vec3 mix_stage_three_AO = mix(mix_stage_two_AO, vec3(AO_b_output.xyz), vec3(z_component_AO));
	vec3 final_AO_mix = mix(vec3(alpha_output_AO.xyz), mix_stage_three_AO, vec3(w_component_AO));
	///////////////////////////////////////////////////////////////////
	///////////////////////////////////////////////////////////////////

	///////////////////////////////////////////////////////////////////
	///////////////////////////ONLY FOR Normal_map ////////////////////////
	//splatmap component
	float x_component_Metalic = splat_map_output.x;
	float y_component_Metalic = splat_map_output.y;
	float z_component_Metalic = splat_map_output.z;
	float w_component_Metalic = splat_map_output.w;
	//Metalic alpha
	vec3 scaled_uv_Metalic = vec3(UV, 0.0) * uv_scale_alpha;
	vec4 alpha_output_Metalic = textureNoTile(alpha_Metalic, vec2(scaled_uv_Metalic.xy));
	//Metalic base
	vec3 scaled_uv_2_Metalic = vec3(UV, 0.0) * uv_scale_base;
	vec4 Metalic_base_output = textureNoTile(Metalic_base, vec2(scaled_uv_2_Metalic.xy));
	//Metalic red
	vec3 scaled_uv_3_Metalic = vec3(UV, 0.0) * uv_scale_R;
	vec4 Metalic_r_output = textureNoTile(Metalic_r, vec2(scaled_uv_3_Metalic.xy));
	//Metalic green
	vec3 scaled_uv_4_Metalic = vec3(UV, 0.0) * uv_scale_G;
	vec4 Metalic_g_output = textureNoTile(Metalic_g, vec2(scaled_uv_4_Metalic.xy));
	//Metalic blue
	vec3 scaled_uv_5_Metalic = vec3(UV, 0.0) * uv_scale_B;
	vec4 Metalic_b_output = textureNoTile(Metalic_b, vec2(scaled_uv_5_Metalic.xy));
	//mixing operation
	vec3 mix_stage_one_Metalic = mix(vec3(Metalic_base_output.xyz), vec3(Metalic_r_output.xyz), vec3(x_component_Metalic));
	vec3 mix_stage_two_Metalic = mix(mix_stage_one_Metalic, vec3(Metalic_g_output.xyz), vec3(y_component_Metalic));
	vec3 mix_stage_three_Metalic = mix(mix_stage_two_Metalic, vec3(Metalic_b_output.xyz), vec3(z_component_Metalic));
	vec3 final_Metalic_mix = mix(vec3(alpha_output_Metalic.xyz), mix_stage_three_Metalic, vec3(w_component_Metalic));
	///////////////////////////////////////////////////////////////////
	///////////////////////////////////////////////////////////////////

	///////////////////////////////////////////////////////////////////
	///////////////////////////ONLY FOR Normal_map ////////////////////////
	//splatmap component
	float x_component_Normal = splat_map_output.x;
	float y_component_Normal = splat_map_output.y;
	float z_component_Normal = splat_map_output.z;
	float w_component_Normal = splat_map_output.w;
	//Normal alpha
	vec3 scaled_uv_Normal = vec3(UV, 0.0) * uv_scale_alpha;
	vec4 alpha_output_Normal = textureNoTile(alpha_Normal, vec2(scaled_uv_Normal.xy));
	//Normal base
	vec3 scaled_uv_2_Normal = vec3(UV, 0.0) * uv_scale_base;
	vec4 Normal_base_output = textureNoTile(Normal_base, vec2(scaled_uv_2_Normal.xy));
	//Normal red
	vec3 scaled_uv_3_Normal = vec3(UV, 0.0) * uv_scale_R;
	vec4 Normal_r_output = textureNoTile(Normal_r, vec2(scaled_uv_3_Normal.xy));
	//Normal green
	vec3 scaled_uv_4_Normal = vec3(UV, 0.0) * uv_scale_G;
	vec4 Normal_g_output = textureNoTile(Normal_g, vec2(scaled_uv_4_Normal.xy));
	//Normal blue
	vec3 scaled_uv_5_Normal = vec3(UV, 0.0) * uv_scale_B;
	vec4 Normal_b_output = textureNoTile(Normal_b, vec2(scaled_uv_5_Normal.xy));
	//mixing operation
	vec3 mix_stage_one_Normal = mix(vec3(Normal_base_output.xyz), vec3(Normal_r_output.xyz), vec3(x_component_Normal));
	vec3 mix_stage_two_Normal = mix(mix_stage_one_Normal, vec3(Normal_g_output.xyz), vec3(y_component_Normal));
	vec3 mix_stage_three_Normal = mix(mix_stage_two_Normal, vec3(Normal_b_output.xyz), vec3(z_component_Normal));
	vec3 final_Normal_mix = mix(vec3(alpha_output_Normal.xyz), mix_stage_three_Normal, vec3(w_component_Normal));
	///////////////////////////////////////////////////////////////////
	///////////////////////////////////////////////////////////////////
	//final output ALBEDO
	ALBEDO = final_albedo_mix; 
	if (Roughness_switch == true){
		ROUGHNESS = final_roughness_mix.x; //alphachannel auto disabled
	}	
	if (AO_switch == true){
		AO = final_AO_mix.x;
	}	
	if (Metalic_switch == true){
		METALLIC = final_Metalic_mix.x;
	}	
	if (Normal_switch == true){
		NORMAL = final_Normal_mix;
		NORMAL_MAP_DEPTH = 10.00;
	}
}
