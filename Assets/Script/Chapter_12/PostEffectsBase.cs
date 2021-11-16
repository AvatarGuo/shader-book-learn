using System;
using System.Collections;
using System.Collections.Generic;
using System.Runtime.Remoting.Messaging;
using UnityEngine;

[ExecuteInEditMode]
[RequireComponent(typeof(Camera))]
public class PostEffectsBase : MonoBehaviour
{
    private bool enable = true;
    // Start is called before the first frame update
    protected void Start()
    {
        checkSupport();
    }


    protected bool checkSupport()
    {
        
        if (!SystemInfo.supportsImageEffects || !SystemInfo.supportsRenderTextures)
        {
            Debug.LogWarning("this platform not support image effects!");
            return false;
        }

        return true;
    }

    protected void notSupport()
    {
        enable = false;
    }

    protected void CheckResources()
    {
        bool support = checkSupport();
        if (!support)
        {
            notSupport();
        }
    }


    protected Material CheckShaderAndCreateMaterial(Shader shader , Material material)
    {
        if (shader == null)
        {
            return null;
        }

        if (shader.isSupported && material && material.shader == shader)
        {
            return material;
        }

        if (!shader.isSupported)
        {
            return null;
        }

        material = new Material(shader);
        // It will not be destroyed when a new Scene is loaded
        material.hideFlags = HideFlags.DontSave;

        if (material)
        {
            return material;
        }

        //返回material
        return null;
    }
}
