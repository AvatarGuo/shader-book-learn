//本质：构建一个三维的空间坐标系
//法线有两种选择，
Shader "Unity Shader book/Chapter11/BillboardShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}

        _Color("Color tint",Color) = ( 1.0 , 1.0, 1.0, 1.0 )
        _VerticalBillboarding("vertical Restraints"  ,Range(0 , 1)) = 0.5
    }
    SubShader
    {
        Tags {
                "RenderType"="Transparent" 
                "IgnoreProjector"="True"
                "Queue"="Transparent"

                //billboard 如果是构建顶点变换的话，顶点动画就要关闭batching了
                "DisableBatching"="True"
            }

        Pass
        {
            Tags
            {
                "LightMode"="ForwardBase"
            }

            ZWrite off
            Blend SrcAlpha OneMinusSrcAlpha
            Cull off

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag


            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;

                //法线normal
                float4 normal : NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            float4 _Color;
            fixed _VerticalBillboarding;



            v2f vert ( appdata v)
            {
                v2f o;
                //顶点动画，在模型中心选择
                fixed3 center = fixed3( 0 , 0 , 0 );
                //_WorldSpaceCameraPos  方向是一个三个维度的值
                fixed3 cameraPos = mul(unity_WorldToObject, fixed4( _WorldSpaceCameraPos , 1.0 )).xyz;



                //构建坐标系,法线，up ,right 
                fixed3 normalDir = normalize(cameraPos - center);

                //还不太理解，为什么呢？
                normalDir.y *= _VerticalBillboarding;

                //粗略的估计上方向
                fixed3 upDir    = abs(normalDir.y) > 0.999 ? float3(0,0,1) : float3(0,1,0);
                float3 rightDir = normalize(cross( normalDir , upDir ));
                upDir  = normalize(cross(rightDir , normalDir ));

                //计算
                float3 centerOffset = v.vertex.xyz - center;
                float3 localPos = center + rightDir * centerOffset.x + upDir * centerOffset.y + normalDir * centerOffset.z;
                //顶点做偏移之后世界坐标就变了
                // fixed3 wPos = mul( unity_ObjectToWorld , v.vertex ).xyz;

                o.vertex = UnityObjectToClipPos(localPos);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
