// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unity Shader book/Chapter5/Simple Shader"
{

    Properties {
        
        _Color ("Color Tint",Color) = ( 1 , 1 , 1 , 1 )

    }

    //等同于openGL中的techniques ： a technique is a collection of one or more passes ,each pass defines a centain way of rendering the object.http://www.catalinzima.com/xna/tutorials/crash-course-in-hlsl/
    subshader {

        pass {

            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag


            //可选参数
            uniform fixed4 _Color;
            //unity 引擎层 是通过meshRender提交模型的自身信息给渲染层的
            //之前42分享的时候，有讲一个优化 ，去掉B-NORMAL,但是unity中appdata_full中也没这个属性 https://docs.unity3d.com/Manual/SL-VertexProgramInputs.html
            // 
            struct a2v {
                float4 vertext : POSITION ;
                float3 normal : NORMAL;       //模型自身的属性，渲染器提供时候类似需要
                float4 texcoord : TEXCOORD0;    //模型自身第一个贴图。即cpu提交给GPU的时候添加的
            };


            struct v2f{
                float4 position :SV_Position; 
                fixed3 color :COLOR0 ;
            };

            //invalid output semantic 'SV_POSITION': Legal indices are in [0,0] at line 43 (on d3d11)
            //https://stackoverflow.com/questions/58543318/invalid-output-semantic-sv-position-legal-indices-are-in-0-0
            v2f vert(a2v v)  { //: SV_POSITION

                //矩阵满足结合律的(AB)C = A(BC)  
                //如果openGL里面的话，(P*V*M , v) 这样顺序
                v2f o;
                o.position = UnityObjectToClipPos(v.vertext);
                o.color = v.normal* 0.5 + fixed3(0.5,0.5,0.5);
                return o ;
            };

            fixed4 frag(v2f i) : SV_Target {
                fixed3 c = i.color;
                c *= _Color.rgb;

                return fixed4( c , 1.0 );
            };

            ENDCG
        }

        //注意 这里刚才写错，多加了一个Pass
        //1 加一个pass就会执行1次。
        //2 pass 和 subshader 支持小写。
        //pass{}
  


    }


}
