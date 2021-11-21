Shader "Unity Shader book/Chapter12/BrightnessSaturationAndContrast"
{
    Properties
    {
        //后处理中 默认为src传过来的。
        _MainTex ("Texture", 2D) = "white" {}
        
        //注意后处理实际是可以省略声明的，声明仅仅是材质球方便设置
        _Brightness("Brightness",float) = 1.0
        _Saturation("Saturation",float) = 1.0
        _Contrast("Constrast",float) = 1.0

        _Color("color tint",color) =(1.0,1.0,1.0,1.0) 
    }
    SubShader
    {
        //tags 要怎么设置，包括queue
        //Tags { "RenderType"="Opaque" }
          
        Pass
        {
            //本质画一个和屏幕长宽的面片 
            //可以设置该面片的Queue  即不透或者transparent 前后去渲染
            ZTest Always 
            Cull off 
            ZWrite off

          	CGPROGRAM  
			#pragma vertex vert  
			#pragma fragment frag  
			  
			#include "UnityCG.cginc"  
			  
			sampler2D _MainTex;  
			half _Brightness;
			half _Saturation;
			half _Contrast;
			  
			struct v2f {
				float4 pos : SV_POSITION;
				half2 uv: TEXCOORD0;
			};
			  
			v2f vert(appdata_img v) {
				v2f o;
				
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv = v.texcoord;
						 
				return o;
			}
		
			fixed4 frag(v2f i) : SV_Target {
				fixed4 renderTex = tex2D(_MainTex, i.uv);  
				  
				// Apply brightness
				fixed3 finalColor = renderTex.rgb * _Brightness;
				
				// Apply saturation
				fixed luminance = 0.2125 * renderTex.r + 0.7154 * renderTex.g + 0.0721 * renderTex.b;
				fixed3 luminanceColor = fixed3(luminance, luminance, luminance);
				finalColor = lerp(luminanceColor, finalColor, _Saturation);
				
				// Apply contrast
				fixed3 avgColor = fixed3(0.5, 0.5, 0.5);
				finalColor = lerp(avgColor, finalColor, _Contrast);
				
				return fixed4(finalColor, renderTex.a);  
			}  
			  
			ENDCG
        }
        

    }
    

    FallBack off

}
