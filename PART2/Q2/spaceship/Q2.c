#include <stdlib.h>
#include <stdio.h>
#include <time.h>
#include <GL/glew.h> // Include the GLEW header file  
#include <GL/glut.h> // Include the GLUT header file  

GLuint bgr;
GLuint ast_tex;
GLuint ast_sph;
GLUquadricObj *sphere;

float random(int N) {
    return ((double)rand() / ((double)RAND_MAX + 1) * N);
}

void renderStars(int numstars) {
    int i=0;
    int distance = 10;
    int space = 5+distance; // works for FOV of 90
    glColor3f(1.0f, 1.0f, 1.0f);
    glPointSize(2.0f);
    glBegin(GL_POINTS);
        for(i=0; i<numstars; i++)
            glVertex3f(random(space)-space/2.0, random(space)-space/2.0, -distance);
    glEnd();
}

void renderAsteroid(float x, float y, float z) {
    glPushMatrix(); // store the location
    glLoadIdentity();
    glRotatef(-90, 1,0,0);
    glTranslatef(0, 5.0f, 0.0f);
    glTranslatef(x, -z, y);  // move the center
    glColor3f(1.0f, 1.0f, 1.0f);    //0.5273f, 0.2578f, 0.1211f);
    glCallList(ast_tex);    // this looks extremely wrong so if something breaks look here
    glPopMatrix();  // restore the location
}

void renderShip(float x, float y, float z) {
    float scale;
    int i;
    int mode;
    mode = GL_POLYGON;
    scale = 0.5f;
    glPushMatrix();
    glTranslatef(x, y, z);
    glColor3f(1.0f, 1.0f, 1.0f);
    for(i=0; i<2; i++)
    {
        glBegin(mode);
            glVertex3f(scale, -scale*2, 0);     // bottom front
            glVertex3f(0, -scale*1.5, 0);       // frontmost point
            glVertex3f(0, -scale, 0);           // another frontmost
            glVertex3f(scale*2, 0, 0);          // top
            glVertex3f(scale*3, 0, 0);          // fin start
            glVertex3f(scale*4, scale/2, 0);    // fin top
            glVertex3f(scale*4.5, scale/2, 0);  // fin end
            glVertex3f(scale*4.5, 0, 0);        // fin end
            glVertex3f(scale*5, -scale*.2, 0);  // back top
            glVertex3f(scale*5, -scale*1.8, 0); // back right
            glVertex3f(scale*4, -scale*2, 0);   // back bottom
        glEnd();
        mode = GL_LINE_LOOP;
        glColor3f(0.0f, 0.0f, 0.0f);
    }
    glPopMatrix();
}

void renderSun(float x, float y, float z) {
    glPushMatrix(); // store the location
    glTranslatef(x, y, z);  // move the center
    glColor3f(1.0f, 1.0f, 0.0f);
    glutSolidSphere(1.0f, 20, 20); //make a sun
    glPopMatrix();  // restore the location
}
  
void display (void) {
    //glClearColor(0.0f, 0.0f, 0.0f, 1.0f); // Clear the background of our window to black  
    
    glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
    glClear(GL_COLOR_BUFFER_BIT); //Clear the colour buffer
    glLoadIdentity(); // Load the Identity Matrix to reset our drawing locations  
    glTranslatef(0.0f, 0.0f, -5.0f);
    
    glEnable(GL_TEXTURE_2D);
    glBindTexture(GL_TEXTURE_2D, bgr);
    //glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA8, 1460, 1024, 0, GL_BGRA, GL_UNSIGNED_BYTE, 1460*1024);
    
    glBegin( GL_QUADS );
        glTexCoord2d(0.0,0.0); glVertex2d(-5.0,-5.0);
        glTexCoord2d(1.0,0.0); glVertex2d(5.0,-5.0);
        glTexCoord2d(1.0,1.0); glVertex2d(5.0,5.0);
        glTexCoord2d(0.0,1.0); glVertex2d(-5.0,5.0);
    glEnd();
    glDisable(GL_TEXTURE_2D);   // color correctly
    
    renderStars(20);
    renderSun(7, 4,-20);
    renderAsteroid(-1.75, -1.25, 0);
    renderShip(0,0,0);
    glFlush(); // Flush the OpenGL buffers to the window  
}

void reshape (int width, int height) {
    glViewport(0, 0, (GLsizei)width, (GLsizei)height); // Set our viewport to the size of our window  
    glMatrixMode(GL_PROJECTION); // Switch to the projection matrix so that we can manipulate how our scene is viewed  
    glLoadIdentity(); // Reset the projection matrix to the identity matrix so that we don't get any artifacts (cleaning up)  
    gluPerspective(60, (GLfloat)width / (GLfloat)height, 1.0, 100.0); // Set the Field of view angle (in degrees), the aspect ratio of our window, and the new and far planes  
    glMatrixMode(GL_MODELVIEW); // Switch back to the model view matrix, so that we can start drawing shapes correctly  
}

GLuint bgTexture(const char* filename, int width, int height, GLenum format)
{
    GLuint bg;
    void* data; // byte-buffer amirite
    FILE* file = fopen(filename, "rb");
    if(file == NULL)
    {
        printf("Oh no!\n");
        return (void*)NULL;
    }
    
    data = malloc(width*height*3);
    fread(data, width*height*3, 1, file);
    fclose(file);
    
    glGenTextures(1, &bg);
    glBindTexture(GL_TEXTURE_2D, bg);
    glTexEnvf(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);
    
    glTexParameterf( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_NEAREST );
    glTexParameterf( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR );
    
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
    
    gluBuild2DMipmaps(GL_TEXTURE_2D, 3, width, height, format, GL_UNSIGNED_BYTE, data);
    
    free(data);
    return bg;
}

int main (int argc, char **argv) {
    srand(time(NULL));  // seed the random
    
    glutInit(&argc, argv); // Initialize GLUT
    glutInitDisplayMode (GLUT_SINGLE); // Set up a basic display buffer (only single buffered for now)  
    glutInitWindowSize (500, 500); // Set the width and height of the window  
    glutInitWindowPosition (100, 100); // Set the position of the window  
    glutCreateWindow ("Space"); // Set the title for the window  
    bgr = bgTexture("stars1.bmp", 1460, 1024, GL_RGB);
    ast_tex = bgTexture("asteroid.bmp", 1024, 512, GL_BGR);

    sphere = gluNewQuadric();
    gluQuadricDrawStyle(sphere, GLU_FILL);
    gluQuadricTexture(sphere, GL_TRUE); // should texture
    gluQuadricNormals(sphere, GL_SMOOTH);

    ast_sph = glGenLists(1);
    glNewList(ast_tex, GL_COMPILE);
        glEnable(GL_TEXTURE_2D);
        glBindTexture(GL_TEXTURE_2D, ast_tex);
        gluSphere(sphere, 1.0, 20, 20);
        glDisable(GL_TEXTURE_2D);
    glEndList();
    gluDeleteQuadric(sphere);

    glutDisplayFunc(display); // Tell GLUT to use the method "display" for rendering
    glutReshapeFunc(reshape); // Tell GLUT to use the method "reshape" for rendering
    glutMainLoop(); // Enter GLUT's main loop
}