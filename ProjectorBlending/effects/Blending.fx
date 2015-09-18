//@author: vvvv group
//@help: this is a very basic template. use it to start writing your own effects. if you want effects with lighting start from one of the GouraudXXXX or PhongXXXX effects
//@tags:
//@credits:

// --------------------------------------------------------------------------------------------------
// PARAMETERS:
// --------------------------------------------------------------------------------------------------

//transforms
float4x4 tW: WORLD;        //the models world matrix
float4x4 tV: VIEW;         //view matrix as set via Renderer (EX9)
float4x4 tP: PROJECTION;
float4x4 tWVP: WORLDVIEWPROJECTION;

//texture
texture Tex            <string uiname="Texture";>;
int     _WallNum       <string uiname="Wall Num";>;
int     _ProjectorNum  <string uiname="Projector Num";>;
float   _BlendFactor1  <string uiname="Blend Factor 1";>;
float   _BlendFactor2  <string uiname="Blend Factor 2";>;
float   _Offset        <string uiname="Blend Offset";>;
float   _OverlayRate   <string uiname="Overlay Rate";>;
float   _Power         <string uiname="Power";>;
float   _Alpha         <string uiname="Alpha";>;
float   _VShift        <string uiname="V Shift";>;

sampler Samp = sampler_state    //sampler for doing the texture-lookup
{
    Texture   = (Tex);          //apply a texture to the sampler
    MipFilter = LINEAR;         //sampler states
    MinFilter = LINEAR;
    MagFilter = LINEAR;
};

//texture transformation marked with semantic TEXTUREMATRIX to achieve symmetric transformations
float4x4 tTex: TEXTUREMATRIX <string uiname="Texture Transform";>;

//the data structure: "vertexshader to pixelshader"
//used as output data with the VS function
//and as input data with the PS function
struct vs2ps
{
    float4 Pos  : POSITION;
    float2 TexCd : TEXCOORD0;
};

// --------------------------------------------------------------------------------------------------
// VERTEXSHADERS
// --------------------------------------------------------------------------------------------------
vs2ps VS(
    float4 PosO  : POSITION,
    float4 TexCd : TEXCOORD0)
{
    //declare output struct
    vs2ps Out;

    //transform position
    Out.Pos = mul(PosO, tWVP);
    
    //transform texturecoordinates
    Out.TexCd = mul(TexCd, tTex);

    return Out;
}

// --------------------------------------------------------------------------------------------------
// PIXELSHADERS:
// --------------------------------------------------------------------------------------------------

float4 PS(vs2ps In): COLOR
{
    
	float2 uv = In.TexCd;
	float  n  = floor(uv.x * _ProjectorNum);
	
	float b = 0.5 - abs((uv.x * _ProjectorNum) - n - 0.5);
	b -= _Offset;
	b *= _BlendFactor1;
			
	b = clamp(b,0,1);
			
	if (b < 0.5){
		b = _Alpha * pow((2*b),_Power);
	} else if (b > 0.5){
		b = 1.0 - (1.0 - _Alpha) * pow((2.0 * (1.0 - b)),_Power);
	}
			
	n -= floor(uv.x * _WallNum);
	if (abs(uv.x * _WallNum - floor(uv.x * _WallNum) - 0.5) > _BlendFactor2){
		b = 1.0;
	}
			
	uv.x -= n * _OverlayRate / _ProjectorNum;
	uv.y += _VShift;
	
	float4 col = tex2D(Samp, uv);
	
	return col * b;
	
	
	/*
	float2 uv  = In.TexCd;
	float2 uv1 = uv;
	
	float f = 1;
	
	if (uv.x < 0.5) {
		uv1.x += _OverlayWidth;
		if (0.5 - _OverlayWidth < uv1.x) {
			f = 1.0 - (uv.x - 0.5 + 2.0 * _OverlayWidth) / (2.0 * _OverlayWidth);
		}
	} else {
		uv1.x -= _OverlayWidth;
		if (uv1.x < 0.5 + _OverlayWidth) {
			f = (uv.x - 0.5) / (2.0 * _OverlayWidth);
		}
	}
	
	if (0.5 - 2.0 * _OverlayWidth < uv.x && uv.x < 0.5 + 2.0 * _OverlayWidth) {
		if (f < 0.5) {
			f = _Alpha * pow ((2.0 * f), _Power);
		} else {
			f = 1.0 - (1.0 - _Alpha) * pow ((2.0 * (1.0 - f)), _Power);
		}
	}
	
	if (uv1.x < 0.0 || 1.0 < uv1.x || uv1.y < 0 || 1.0 < uv1.y) {
		f = 0.0;
	}

    return col * f;
	*/
}

// --------------------------------------------------------------------------------------------------
// TECHNIQUES:
// --------------------------------------------------------------------------------------------------

technique TSimpleShader
{
    pass P0
    {
        //Wrap0 = U;  // useful when mesh is round like a sphere
        VertexShader = compile vs_1_1 VS();
        PixelShader  = compile ps_2_0 PS();
    }
}

technique TFixedFunction
{
    pass P0
    {
        //transforms
        WorldTransform[0]   = (tW);
        ViewTransform       = (tV);
        ProjectionTransform = (tP);

        //texturing
        Sampler[0] = (Samp);
        TextureTransform[0] = (tTex);
        TexCoordIndex[0] = 0;
        TextureTransformFlags[0] = COUNT2;
        //Wrap0 = U;  // useful when mesh is round like a sphere
        
        Lighting       = FALSE;

        //shaders
        VertexShader = NULL;
        PixelShader  = NULL;
    }
}
