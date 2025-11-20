using UnityEngine;

[RequireComponent(typeof(Rigidbody))]
public class ShipWaveFollower : MonoBehaviour
{
    public Material waterMat; // material using CartoonWater.shader or Shader Graph material
    public float heightOffset = 0.0f;
    public float tiltStrength = 8f;
    // sampling offsets for slope
    public float sampleOffset = 0.6f;

    void Update()
    {
        Vector3 p = transform.position;
        float t = Time.time;

        float h = SampleWaves(p.x, p.z, t);
        p.y = h + heightOffset;
        transform.position = p;

        float hx = SampleWaves(p.x + sampleOffset, p.z, t) - SampleWaves(p.x - sampleOffset, p.z, t);
        float hz = SampleWaves(p.x, p.z + sampleOffset, t) - SampleWaves(p.x, p.z - sampleOffset, t);

        // convert slope to tilt angles (degrees)
        Vector3 tiltEuler = new Vector3(-hz * tiltStrength, transform.eulerAngles.y, hx * tiltStrength);
        transform.rotation = Quaternion.Euler(tiltEuler);
    }

    float SampleWaves(float x, float z, float t)
    {
        // match names from shader properties
        float amp0 = waterMat.GetFloat("_WaveAmp");
        float len0 = waterMat.GetFloat("_WaveLen");
        float spd0 = waterMat.GetFloat("_WaveSpeed");

        float amp1 = waterMat.GetFloat("_WaveAmp1");
        float len1 = waterMat.GetFloat("_WaveLen1");
        float spd1 = waterMat.GetFloat("_WaveSpeed1");

        float amp2 = waterMat.GetFloat("_WaveAmp2");
        float len2 = waterMat.GetFloat("_WaveLen2");
        float spd2 = waterMat.GetFloat("_WaveSpeed2");

        float TWO_PI = 6.283185307179586f;

        float Wave(float px, float pz, Vector2 dir, float amp, float len, float spd) {
            float k = TWO_PI / len;
            float phase = (px * dir.x + pz * dir.y) * k + t * spd;
            return Mathf.Sin(phase) * amp;
        }

        Vector2 pos = new Vector2(x, z);

        float h = 0;
        h += Wave(x, z, new Vector2(1f, 0f), amp0, len0, spd0);
        h += Wave(x, z, new Vector2(0.5f, 0.5f), amp1, len1, spd1);
        h += Wave(x, z, new Vector2(-1f, 0.3f), amp2, len2, spd2);

        // sample ripple parameters (optional)
        Vector4 rippleC = waterMat.GetVector("_RippleCenter");
        float rippleStrength = waterMat.GetFloat("_RippleStrength");
        float rippleTime = waterMat.GetFloat("_RippleTime");

        if (rippleStrength > 0.0001f) {
            float d = Vector2.Distance(new Vector2(x, z), new Vector2(rippleC.x, rippleC.z));
            float ripple = Mathf.Sin(d * 12f - rippleTime * 4f) * Mathf.Exp(-d * 2f) * rippleStrength;
            h += ripple;
        }

        return h;
    }
}
