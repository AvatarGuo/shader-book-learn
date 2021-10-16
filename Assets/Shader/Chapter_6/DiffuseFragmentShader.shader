Shader "Unity Shader book/Chapter6/Diffuse fragment Shader"
{
    Properties
    {
        _Diffuse("Diffuse",color) = (1,1,1,1)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque"  "LightMode" = "ForwardBase" }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
    

            #include "UnityCG.cginc"
            #include "UnityLightingCommon.cginc"


            fixed4 _Diffuse;

            struct appdata
            {
                float4 vertex : POSITION;
                float4 normal : NORMAL;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                fixed3 normal:COLOR0; //如果是normal了 还用color0填充吗？

            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);

                //法线要不要归一化呢？归一化值可能会变
                //只用缩放矩阵，不用齐次坐标
                o.normal =  mul( v.normal ,(float3x3)unity_WorldToObject);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                //环境光
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
 
                fixed3 normal = normalize(i.normal);
                fixed3 lightDir = normalize (_WorldSpaceLightPos0.xyz);


                fixed3 lightColor = _LightColor0.xyz ; 


                fixed3 color = _Diffuse.xyz * lightColor * saturate(dot(normal,lightDir));

                color  += ambient;
                return fixed4(color,1);
            }

            ENDCG
        }
    }

    Fallback "Diffuse"
}
