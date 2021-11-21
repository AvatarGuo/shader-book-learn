Shader "Unity Shader book/Chapter12/BloomShader"
{
	Properties
	{
		
		//后处理中直接_MainTex 为src传过来的值
		_MainTex ("Texture", 2D) = "white" {}

		//可以不设置，这里仅仅是inspector中方便查看
		_Bloom("Bloom(RGB)",2D) = "white" {}
		_LuminanceThreshold("lumianceThreshold" ,Float) = 0.5
		_BlurSize("Blur size",Float) = 1.0

	}
	
	//bloom 扩散到其他区域

	SubShader
	{
		
		CGINCLUDE

		#include "UnityCG.cginc"

		sampler2D _MainTex;
		fixed2 _MainTex_TexelSize; //取像素中心点的位置，需要定义 ? 书上是float4类型 为什么 ？

		sampler2D _Bloom;
		float _LuminanceThreshold;
		float _BlurSize;

		//定义第一个类型pass ,提取出来高亮部分
		struct v2f
		{
			float4 pos: SV_POSITION;
			half2  uv : TEXCOORD0;
		
		};

		//提取高亮部分 ，限制到0-1 范围内，提取出来对应的亮度部分。

		v2f vertExtractBright(appdata_img v)
		{
			v2f o;
			
			o.pos = UnityObjectToClipPos(v.vertex);
			o.uv  = v.texcoord;
			
			return o;

		};


		//亮度公式 hdr 求高亮的公式
		fixed lumiance(fixed4 color ){
		
			return 0.2125 * color.r + 0.7154 * color.g + 0.0721 * color.b;
		};


		fixed4 fragExtractBright(v2f i):SV_Target
		{
			fixed4 color = tex2D(_MainTex,i.uv);
			
			//获取当前像素点的亮度
			fixed lu = lumiance(color);

			//同saturate() shader取值到0,1范围内
			fixed val = clamp(lu - _LuminanceThreshold , 0.0 ,1.0);
			return color * val;

		};



		//混合局部亮度和原图片
//		struct v2fBloom
//		{
//			float4 pos:SV_POSITION;
//			float4 uv;TEXCOORD0;
//		};

		struct v2fBloom {
			float4 pos : SV_POSITION; 
			half4 uv : TEXCOORD0;
		};

		v2fBloom vertBloom(appdata_img v){
			v2fBloom  o;

			o.pos =  UnityObjectToClipPos(v.vertex);
			o.uv.xy = v.texcoord; //没有用TRANSFORM_TEX

			o.uv.zw = v.texcoord;

			#if UNITY_UV_STARTS_AT_TOP
			if (_MainTex_TexelSize.y < 0){

				o.uv.w = 1.0 - o.uv.w; 
			}
			#endif

			return o;

		}


		fixed4 fragBloom(v2fBloom i):SV_Target
		{
			//bloom 直接将两个图片叠加起来就行，
			//图片叠加，即需要考虑下双层uv即可。
			return tex2D(_MainTex , i.uv.xy) + tex2D(_Bloom , i.uv.zw);
		
		}


		ENDCG

		ZTest Always  ZWrite off Cull off

		//定义第0个pass
		Pass
		{
			CGPROGRAM
			
			#pragma vertex vertExtractBright
			#pragma fragment fragExtractBright
			
			ENDCG

		}


		//第1个pass
		UsePass "Unity Shader book/Chapter12/GaussionShader/GAUSSIAN_BLUR_VERTICAL"

		//第2个pass
		UsePass "Unity Shader book/Chapter12/GaussionShader/GAUSSIAN_BLUR_HORIZONTAL"

		//第3个pass,混合bloom 和原图

		pass
		{
			
			CGPROGRAM
			
			#pragma vertex vertBloom
			#pragma fragment fragBloom
			
			ENDCG
		}

	}

	Fallback off
}
