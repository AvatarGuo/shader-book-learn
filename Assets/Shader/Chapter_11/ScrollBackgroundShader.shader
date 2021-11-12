Shader "Unity Shader book/Chapter11/ScrollBackgroundShader"
{
    Properties
    {
        _MainTex ("base Texture", 2D) = "white" {}
        _DetailTex("detail Texture",2D) = "white" {}

        _ScrollX("scroll x speend" ,float ) = 1.0
        _Scroll2X("2nd layer speed",float ) = 1.0

        _MultiPlayer("multi player ",float) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }


        Pass
        {
            Tags {

                "LightMode"="ForwardBase"

            }
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                //插值寄存器，因为最后会算平均
                float4 uv : TEXCOORD0; //两个贴图的uv采样
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            sampler2D _DetailTex;
            float4 _DetailTex_ST;

            fixed _ScrollX;
            fixed _Scroll2X;
            fixed _MultiPlayer;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv.xy = TRANSFORM_TEX(v.uv ,  _MainTex) + frac( float2( _ScrollX , 0 )  * _Time.y ) ;
                //在单独用个寄存器计算detail 的偏移
                //实际也可以少用个寄存器，在ps里面两个速度即可
                o.uv.zw = TRANSFORM_TEX(v.uv , _DetailTex) + frac( float2( _Scroll2X , 0 )  * _Time.y ) ; ; 

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                //两个贴图混合还没有弄过
                // sample the texture
                fixed4 baseTex = tex2D( _MainTex, i.uv.xy);
                fixed4 addTex  = tex2D( _DetailTex,i.uv.zw);

                //用a通道做lerp，完美混合！ 
                // return  baseTex + addTex;
                fixed3 color = lerp(baseTex,addTex,addTex.a);

                color *= _MultiPlayer;
                return fixed4( color,1.0);
            }
            ENDCG
        }
    }
}
