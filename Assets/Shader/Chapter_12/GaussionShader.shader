Shader "Unlit/GaussionShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _BlurSize("Blur size",float) = 1.0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        Pass
        {
            ZTest Always
            Cull off
            ZWrite off

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag


            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                half2 uv[5]:TEXCOORD0;
                float4 vertex : SV_POSITION;
            };



            v2f vertexBlurVertical(appdata v){
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);

                o.uv[0] = v.uv;

                o.uv[1] = v.uv + half2( 0.0 ,  _MainTex_TexelSize.y * 1.0) * _BlurSize;
                o.uv[2] = v.uv - half2( 0.0 ,  _MainTex_TexelSize.y  * 1.0) * _BlurSize;

                o.uv[3] = v.uv + half2( 0.0 , _MainTex_TexelSize.y * 2.0) * _BlurSize;
                o.uv[4] = v.uv - half2( 0.0,  _MainTex_TexelSize.y  * 2.0) * _BlurSize;

            };


            v2f vertexBlurHorizontal(appdata v){
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);

                o.uv[0] = v.uv;

                o.uv[1] = v.uv + half2(  _MainTex_TexelSize.x  * 1.0  , 0.0) * _BlurSize;
                o.uv[2] = v.uv - half2(  _MainTex_TexelSize.x  * 1.0  , 0.0) * _BlurSize;

                o.uv[3] = v.uv + half2(  _MainTex_TexelSize.x *  2.0 , 0.0) * _BlurSize;
                o.uv[4] = v.uv - half2(  _MainTex_TexelSize.x  * 2.0 , 0.0) * _BlurSize;
            };



            sampler2D _MainTex;
            //shader中可以直接采样uv，不用计算了
            //float4 _MainTex_ST;

            float _BlurSize;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                half2 uv = v.uv;


                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
             
                return col;
            }
            ENDCG
        }
    }
}
