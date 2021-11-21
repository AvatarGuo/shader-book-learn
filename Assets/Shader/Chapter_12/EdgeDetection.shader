Shader "Unity Shader book/Chapter12/EdgeDetection"
{
    Properties
    {
        //可以不用设置。重点是卷积核的大小
        _MainTex ("Texture", 2D) = "white" {}

        _EdgeOnly("edge",range(0,1.0)) = 0.5
        _EdgeColor("edge color",color) =( 1.0, 1.0, 1.0, 1.0)
        _BackgroundColor("background color",color) = (1.0, 1.0, 1.0, 1.0)
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
                //  float2 uv : TEXCOORD0;
                //  还可以定义数组吗？ 奇怪
                half2 uv[9]:TEXCOORD0; 
           
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            //新的一个变量
            //如ramp对贴图降采样等手段用的方式
            //即downsamle 需要对贴图做一些缩放等效果
            float2 _MainTex_TexelSize;

            
            float _EdgeOnly;
            float4 _EdgeColor;
            float4 _BackgroundColor;


            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                //o.uv = TRANSFORM_TEX(v.uv, _MainTex);

                //uv 转化，降采样的方法
                //需要scale的话 也可以直接使用Transp
                
                //注意下面的每一个都是二维的
                      //定义一个卷积核
                half2 uv = v.uv;

                o.uv[0] = uv + _MainTex_TexelSize.xy * half2(-1,-1);
                o.uv[1] = uv + _MainTex_TexelSize.xy * half2(0,-1);
                o.uv[2] = uv + _MainTex_TexelSize.xy * half2(1,-1);

          
                o.uv[3] = uv + _MainTex_TexelSize.xy * half2(-1 , 0);
                o.uv[4] = uv + _MainTex_TexelSize.xy * half2( 0 , 0);
                o.uv[5] = uv + _MainTex_TexelSize.xy * half2( 1 , 0);
                
                //
                o.uv[6] = uv + _MainTex_TexelSize.xy * half2(-1,1);
                o.uv[7] = uv + _MainTex_TexelSize.xy * half2(0, 1);
                o.uv[8] = uv + _MainTex_TexelSize.xy * half2(1,1);

                return o;
            }

            //hdr三个方向展开的公式
            fixed lumiance(fixed4 in_color)
            {
                // hdr 相关
                return 0.2125 * in_color.r + 0.7154 * in_color.g + 0.0721 * in_color.b;

            }

            half sobel(v2f i)
            {
                //定义一个卷积核，并且可以用const来表示
                const half  Gx[9] = {
                    -1, -2, -1,
                     0,  0, 0,
                     1,  2 , 1
                };


                const half Gy[9] = {
                    -1,0,1,
                    -2,0,2,
                    -1,0,1
                };

                //本质是做平均的，即求一个点周围的平均点
                half texelColor;
                half edgeX = 0;
                half edgeY = 0;

                for(int it = 0; it < 9 ; it ++){
                    //取周围一圈像素，如果边缘不存在的话，底层应该会返回一个0过来吧。
                    texelColor = tex2D( _MainTex ,i.uv[it]);
                    
                    edgeX += texelColor * Gx[it];
                    edgeY += texelColor * Gy[it];
               }

               half edge = 1- abs(edgeX) - abs(edgeY);
               return edge;
            }


            fixed4 frag (v2f i) : SV_Target
            {
                half edge = sobel(i);
                fixed4 oriColor = tex2D(_MainTex,i.uv[4]);

                fixed4 withEdgeColor = lerp(_EdgeColor ,oriColor ,edge);
                //fixed4 onlyEdgeColor = lerp(_EdgeColor,_BackgroundColor,edge);

                //return lerp(withEdgeColor , onlyEdgeColor ,_EdgeOnly);
                return withEdgeColor;
            }
            ENDCG
        }
    }
}
