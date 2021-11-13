Shader "Unity Shader book/Chapter11/WaterShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Color("color",color) = (1.0, 1.0 ,1.0 ,1.0)

        _Magnitude("Distoriation magnitude",float) = 1
        _Frequency("Distortion Frequency",float) = 1
        _InWaveLength("InWave length",float) = 10
        _Speed("speed",float) = 1.0
    }
    SubShader
    {
        Tags { 
            "RenderType"="Transparent"
            "Queue"="Transparent"
            "IgnoreProject"="True"

            //取消合批本质也是一个优化
            //因为合批每一帧的顶点变化了 都要重新batch ，所以反而更耗，这样就直接告诉底层，不用处理合批了
            "DisableBatching"="True"

        }
        LOD 100

        Pass
        {
            Tags {
                "LightMode"="ForwardBase"
            }

            ZWrite off
            Blend SrcAlpha  OneMinusSrcAlpha
            Cull off

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag


            #include "UnityCG.cginc"
            #include "UnityLightingCommon.cginc"
            #include "AutoLight.cginc" //shadow

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            fixed4 _Color;
            fixed _Magnitude;
            fixed _Frequency;
            fixed _InWaveLength;
            fixed _Speed;


            v2f vert (appdata v)
            {
                //对顶点做个偏移
                v2f o;
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);

                float4 offset;
                offset.yzw = float3(0.0,.0,.0);
                offset.x = sin(_Frequency * _Time.y + v.vertex.x  * _InWaveLength +v.vertex.y * _InWaveLength + v.vertex.z * _InWaveLength) * _Magnitude;

                o.vertex = UnityObjectToClipPos(v.vertex + offset);
                o.uv += float2( 0.0 ,_Time.y * _Speed);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                col.rgb *= _Color.xyz;
                return col;
            }
            ENDCG
        }
    }
}
