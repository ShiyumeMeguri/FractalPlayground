using System;
using UnityEngine;

#if ENABLE_INPUT_SYSTEM
using UnityEngine.InputSystem;
#endif

namespace ReformSim
{
    public class ImageShaderKeyboardInput : MonoBehaviour
    {
        public enum TextureNameType
        {
            MainTex,
            SecondTex,
            ThirdTex,
            FourthTex,
        }

        public TextureNameType m_textureNameType = TextureNameType.MainTex;
        protected string m_textureName;

        // Row 0: contain the current state of the 256 keys. 
        // Row 1: contains Keypress.
        // Row 2: contains a toggle for every key.
        // Texel positions correspond to ASCII codes.
        protected Color[] m_keyboardData0 = new Color[256];
        protected Color[] m_keyboardData1 = new Color[256];
        protected Color[] m_keyboardData2 = new Color[256];
        public Texture2D m_keyboardDataTex;
        protected FilterMode m_texFilterMode = FilterMode.Point;

        public Material m_material = null;

        protected void Start()
        {
            m_keyboardDataTex = new Texture2D(256, 3, TextureFormat.R8, false, true);
            m_keyboardDataTex.filterMode = m_texFilterMode;

            if (m_material == null)
            {
                Renderer render = GetComponent<Renderer>();
                m_material = render.material;
            }

            m_textureName = "_" + m_textureNameType.ToString();
            m_material.SetTexture(m_textureName, m_keyboardDataTex);
        }

        protected void Update()
        {
            for (int i = 0; i < m_keyboardData0.Length; i++)
            {
                if (!Enum.IsDefined(typeof(KeyCode), i))
                {
                    continue;
                }

                KeyCode keyCode = (KeyCode)i;

                UpdateKeyboardData(i, keyCode);

#if ENABLE_INPUT_SYSTEM
                UpdateKeyboardData(37, Key.LeftArrow);
                UpdateKeyboardData(38, Key.UpArrow);
                UpdateKeyboardData(39, Key.RightArrow);
                UpdateKeyboardData(40, Key.DownArrow);
#else
                UpdateKeyboardData(37, KeyCode.LeftArrow);
                UpdateKeyboardData(38, KeyCode.UpArrow);
                UpdateKeyboardData(39, KeyCode.RightArrow);
                UpdateKeyboardData(40, KeyCode.DownArrow);
#endif
            }

            m_keyboardDataTex.SetPixels(0, 0, m_keyboardData0.Length, 1, m_keyboardData0, 0);
            m_keyboardDataTex.SetPixels(0, 1, m_keyboardData1.Length, 1, m_keyboardData1, 0);
            m_keyboardDataTex.SetPixels(0, 2, m_keyboardData2.Length, 1, m_keyboardData2, 0);
            
            m_keyboardDataTex.Apply();
        }

        protected void UpdateKeyboardData(int assiiCode, KeyCode keyCode)
        {
            if (Input.GetKey(keyCode))
            {
                m_keyboardData0[assiiCode] = Color.red;
            }
            else
            {
                m_keyboardData0[assiiCode] = Color.black;
            }

            if (Input.GetKeyDown(keyCode))
            {
                m_keyboardData1[assiiCode] = Color.red;
            }
            else
            {
                m_keyboardData1[assiiCode] = Color.black;
            }

            if (Input.GetKeyUp(keyCode))
            {
                m_keyboardData2[assiiCode] = m_keyboardData2[assiiCode] == Color.red ? Color.black : Color.red;
            }
        }

#if ENABLE_INPUT_SYSTEM
        protected void UpdateKeyboardData(int assiiCode, Key key)
        {
            if (Keyboard.current[key].isPressed)
            {
                m_keyboardData0[assiiCode] = Color.red;
            }
            else
            {
                m_keyboardData0[assiiCode] = Color.black;
            }

            if (Keyboard.current[key].wasPressedThisFrame)
            {
                m_keyboardData1[assiiCode] = Color.red;
            }
            else
            {
                m_keyboardData1[assiiCode] = Color.black;
            }

            if (Keyboard.current[key].wasReleasedThisFrame)
            {
                m_keyboardData2[assiiCode] = m_keyboardData2[assiiCode] == Color.red ? Color.black : Color.red;
            }
        }
#endif

//#if UNITY_EDITOR
//        public bool m_debugShowRenderTextures = false;

//        protected void OnGUI()
//        {
//            ShowRenderTextures(m_debugShowRenderTextures);
//        }
//#endif

        public void ShowRenderTextures(bool showRenderTexture)
        {
            if (showRenderTexture)
            {
                if (m_keyboardDataTex != null)
                {
                    GUI.DrawTexture(new Rect(0, 100, m_keyboardDataTex.width*2, m_keyboardDataTex.height*100), m_keyboardDataTex, ScaleMode.ScaleAndCrop, false);
                }
            }
        }

        protected void OnDestroy()
        {
            Destroy(m_keyboardDataTex);
        }
    }
}