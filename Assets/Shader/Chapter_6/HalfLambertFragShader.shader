Shader "Unity Shader book/Chapter6/half lambert fragment Shader"
{
    Properties
    {
        _Diffuse ("Diffuse", color) = (1 ,1 ,1 ,1 )
    }
    SubShader
    {

        
        Tags { 
                "RenderType"="Opaque"  
                "LightMode"="ForwardBase" 
            }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag


            #include "UnityCG.cginc"
            #include "UnityLightingCommon.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float4 normal:NORMAL;
            };

            struct v2f
            {
                float4 vertex :SV_POSITION;
                fixed3 normal:NORMAL;

            };

           fixed4 _Diffuse;

            v2f vert (appdata v)
            {
                v2f o;

                o.vertex = UnityObjectToClipPos(v.vertex);
                o.normal = mul(v.normal,(float3x3)unity_WorldToObject); //这里不能进行归一化

                return o;


            };

            fixed4 frag (v2f i) : SV_Target
            {
                //环境光
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

                //half lambert 计算
                fixed3 normal = normalize(i.normal); //保险起见，因为值还要平均，所以在ps里面进行平均和归一化
                fixed3 worldNormal = normalize(_WorldSpaceLightPos0.xyz);


                fixed3 halfLambert =  dot(normal,worldNormal) * 0.5 + 0.5;


                fixed3 lightColor = _LightColor0.xyz;
                fixed3 diffuse = lightColor * _Diffuse * halfLambert ;

                fixed3 color = diffuse + ambient;
                return fixed4( color , 1.0 );


              
            };
            ENDCG
        }

    }

}
