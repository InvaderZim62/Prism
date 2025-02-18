# Prism

Simulation of the defraction of light through a prism, based on Snell's law.

Tap an object to select, then pan or rotate it.

![Prism](https://github.com/user-attachments/assets/29161d29-6257-472f-acd4-db1a04280ca9)

https://github.com/user-attachments/assets/4fc1d941-ddcb-47d6-bd31-7c0fc5486e0c

## Methodology

The app traces 39 different wavelengths of light from a light source through "air", until it encounters a prism or mirror (or goes off screen).  Each wavelength of light bends a different amount at the prism walls, depending on it's index of refraction.  I cheat a little and draw one last white line on top, so it looks like white light comming from the light source.

If the light exiting a prism bends enough that it becomes parallel to the surface, it starts to reflect back into the prism, as shown in this video: [Light beam and rotating prism, animation](https://www.sciencephoto.com/media/727340/view/light-beam-and-rotating-prism-animation).

## References

This is the index of refraction of light at different wavelengths through glass, from this reference: [Optical Properties of Glass](https://www.koppglass.com/blog/optical-properties-glass-how-light-and-glass-interact).

![Index of refraction](https://github.com/user-attachments/assets/b8622a08-30d1-403d-89f9-4df8bb0c21c8)

Using [Snell's Law](https://en.wikipedia.org/wiki/Snell%27s_law) and the angle of incidence of the light, you can compute how much each wavelenght of light bends going through the glass.

To convert from wavelength to color, I used the code found here: [StackOverflow](https://stackoverflow.com/a/14917481/2526464).

![colors](https://github.com/user-attachments/assets/1931236c-2fd6-4576-9f13-2cd0fa105023)
