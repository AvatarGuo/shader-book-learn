Shader "Unity Shader book/Chapter13/MotionBlurWithDepthTextureShader"
{
	Properties
	{
		_MainTex ("Texture", 2D) 	= "white" {}
		_BlurSize("BlurSize",float) = 0.5

	}
	SubShader
	{
		CGINCLUDE

		#include "UnityCG.cginc"
		#include "HLSLSupport.cginc"

		sampler2D _MainTex; //获取图片纹素，即当前的x,y信息
		float2 _MainTex_TexelSize;  //x，y 就能表示了,zw 存储的是啥

		float _BlurSize;  //模糊程度
		float4x4 _PreWorlldToProjectMatrix;
		float4x4 _CurProjectToWorldMatrix;
		
		
		sampler2D _CameraDepthTexture;  //获取深度图


		struct v2f
		{
			float4 	pos			:	SV_POSITION;
			half2  	uv			:	TEXCOORD0;
			half2 	uv_depth	:	TEXCOORD1;
		};


		v2f vert(appdata_img v){
			v2f o;
			o.pos = UnityObjectToClipPos(v.vertex);

			//木有用scale ，tile 就不用TransTex
			o.uv = v.texcoord;
			o.uv_depth = v.texcoord;

			#if UNITY_UV_STARTS_AT_TOP
				o.uv_depth.y = 1.0 - o.uv.y;
			#endif

			return o;
		};

		
		fixed frag(v2f i):SV_Target
		{

			//图片原始的x,y已经知道了，现在要获得深度值，但是深度值被压缩了，所以深度要变成线性深度值
			float d = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture , i.uv.uv_depth);
			//ndc空间本身z值就是非线性的
			float4 projection_info =  float4(i.uv.x*2 - 1 ,u.uv.y *2 -1 , d * 2 - 1 , 1.0 ); //都已经被限制到-1，1了，所以直接w取1

			float4 d 	= mul( _CurProjectToWorldMatrix, projection_info);
			float4 worldPos = d/d.w; //获取世界坐标

			//
			float4 curPos = projection_info;
			//上一步骤获得的世界坐标，获取上一个世界坐标
			float4 prePos = mul(_PreWorlldToProjectMatrix,worldPos );
			prePos = prePos/prePos.w;


			//计算下速度
			float velocity = curPos.xy - prePos.xy;

			float2 uv = i.uv;
			float4 color  = tex2D(_MainTex,uv);

			uv += velocity * _BlurSize;
			for(int it =0 ; it < 3; it++){
				uv += velocity * _BlurSize;
				float4 velColor =  tex2D(_MainTex,uv);
				color += velColor;
			}
			color/=3;

			return fixed4(color.rgb ,1.0);

		}


		ENDCG


		Pass
		{
			ZTest Always ZWrite off Cull off
			CGPROGRAM

			#pragma vertex vert
			#pragma fragment frag
			
			ENDCG

		}


	}

	Fallback off
}
