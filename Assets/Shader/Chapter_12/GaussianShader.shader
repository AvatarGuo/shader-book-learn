Shader "Unlit/GaussionShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _BlurSize("Blur size",float) = 1.0
    }
    SubShader
    {
        CGINCLUDE
       
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


        sampler2D _MainTex;
        //shader中可以直接采样uv，不用计算了
        //float4 _MainTex_ST;
        float2 _MainTex_TexelSize;

        float _BlurSize;



        v2f vertexBlurVertical(appdata v){
            v2f o;
            o.vertex = UnityObjectToClipPos(v.vertex);

            o.uv[0] = v.uv;

            o.uv[1] = v.uv + half2( 0.0 ,  _MainTex_TexelSize.y * 1.0) * _BlurSize;
            o.uv[2] = v.uv - half2( 0.0 ,  _MainTex_TexelSize.y  * 1.0) * _BlurSize;

            o.uv[3] = v.uv + half2( 0.0 , _MainTex_TexelSize.y * 2.0) * _BlurSize;
            o.uv[4] = v.uv - half2( 0.0,  _MainTex_TexelSize.y  * 2.0) * _BlurSize;
            return o;
        };


        v2f vertexBlurHorizontal(appdata v){
            v2f o;
            o.vertex = UnityObjectToClipPos(v.vertex);

            o.uv[0] = v.uv;

            o.uv[1] = v.uv + half2(  _MainTex_TexelSize.x  * 1.0  , 0.0) * _BlurSize;
            o.uv[2] = v.uv - half2(  _MainTex_TexelSize.x  * 1.0  , 0.0) * _BlurSize;

            o.uv[3] = v.uv + half2(  _MainTex_TexelSize.x *  2.0 , 0.0) * _BlurSize;
            o.uv[4] = v.uv - half2(  _MainTex_TexelSize.x  * 2.0 , 0.0) * _BlurSize;

            return o;
        };


        fixed4 fragBlur(v2f i):SV_Target
        {
            float weight[3] = { 0.4026 , 0.2442 , 0.0545 };
                
            fixed3 sum = tex2D( _MainTex , i.uv[0]).rgb * weight[0];
    
            
            //for遍历尽量别用i 容易和v2f 的i 重叠
            for(int it = 1 ; it < 3 ; it ++ ){
                sum += tex2D( _MainTex , i.uv[it*2-1]).rgb * weight[it];
                sum += tex2D( _MainTex , i.uv[it*2]).rgb * weight[it];
            }
            return fixed4(sum,1.0);
        };

        ENDCG
        
    
    ZTest Always ZWrite off  Cull off

    pass{
            
        Name "GAUSSIAN_BLUR_VERTICAL"

        CGPROGRAM
        #pragma vertex vertexBlurVertical
        #pragma fragment fragBlur
        ENDCG
    }


    pass{
        Name  "GAUSSIAN_BLUR_HORIZONTAL"

        CGPROGRAM
        #pragma vertex vertexBlurHorizontal
        #pragma fragment fragBlur
        ENDCG


    }


   
   }

   FallBack "Diffuse"
}
