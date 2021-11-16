using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class BrightnessSaturationAndContrast : PostEffectsBase
{

    public Shader BrightSatConShader;
    private Material brightSatMat;

    [Range(0.0f,3.0f)]
    public float brightness;

    [Range(0.0f, 3.0f)]
    public float saturation;

    [Range(0.0f, 3.0f)]
    public float contrast;

    public Material material
    {
        get
        {
            brightSatMat = CheckShaderAndCreateMaterial(BrightSatConShader, brightSatMat);
            return brightSatMat;
        }
    }

    void OnRenderImage(RenderTexture src,RenderTexture dst)
    {
        if (material != null)
        {
            material.SetFloat("_brightness", brightness);
            material.SetFloat("_saturation", saturation);
            material.SetFloat("_contrast", contrast);

            Graphics.Blit(src,dst,material);
        }
        else
        {
            Graphics.Blit(src,dst);
        }

    }

}
