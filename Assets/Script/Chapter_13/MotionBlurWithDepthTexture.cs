using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class MotionBlurWithDepthTexture : PostEffectsBase
{

    public Material _material;
    public Shader motionBlurDepthShader;
    public Material material
    {
        get
        {
            if (_material == null)
            {
                _material = CheckShaderAndCreateMaterial( motionBlurDepthShader , _material );
            }
            return _material;

        }
    }

    [UnityEngine.Range(0f , 1.0f)]
    public float blurSize = 0.5f;


    private Camera _camera;

    public Camera camera
    {
        get
        {
            if (_camera == null)
            {
                _camera = this.gameObject.GetComponent<Camera>();
                // Assert.IsTrue(_camera != null, string.Format("[MotionBlurWithDepthTexture] this object : {0} not have camera ", this.gameObject.name));
            }
            return _camera;
        }
    }


    /// <summary>
    /// 上一帧世界转ndc空间矩阵
    /// </summary>
    private Matrix4x4 _preWorld2ProjectMatrix;

    //写错了效果
    void OnRenderImage(RenderTexture src ,RenderTexture dst)
    {

        //现在的前提是只有当前帧的位置信息（x,y 即 uv. z 即 SAMPLE_DEPTH_TEXTURE 在shader中采样 ）
        if (material != null && camera != null)
        {
            //前后两帧设置值
            material.SetFloat("_BlurSize",blurSize);
            material.SetMatrix("_PreWorlldToProjectMatrix", _preWorld2ProjectMatrix);
            
            //unity这里面是左乘的 p*v*m * A 
            Matrix4x4 _curWorld2ProjectMatrix = camera.projectionMatrix * camera.worldToCameraMatrix;

            //shader中采样的 x , y 和 z 值，都是0-1范围内的，要转化成ndc，然后再转化到 (贴图只能保存0-1范围内的值，但是法线的范围是-1,1范围，所以采样法线贴图需要 [0,1]*2 -1,先归一化到0，1范围内 )
            Matrix4x4 _curProject2WorldMatirx = _curWorld2ProjectMatrix.inverse;
            material.SetMatrix("_CurProjectToWorldMatrix", _curProject2WorldMatirx);

            _preWorld2ProjectMatrix = _curWorld2ProjectMatrix;
            //世界坐标的点 转到ndc坐标中

            //指定的index
            Graphics.Blit(src,dst,material);
        }
        else
        {
            Graphics.Blit(src,dst);
        }
    }


    void OnEnable()
    {
        camera.depthTextureMode |= DepthTextureMode.Depth;

        //还是要考虑第一帧
        _preWorld2ProjectMatrix = camera.projectionMatrix * camera.worldToCameraMatrix;


    }
}
