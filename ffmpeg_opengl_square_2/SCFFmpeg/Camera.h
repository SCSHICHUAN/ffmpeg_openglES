//
//  Camera.h
//  opengl环境
//
//  Created by Stan on 2022/12/24.
//

#ifndef Camera_h
#define Camera_h


#include <glm/glm.hpp>
#include <glm/gtc/matrix_transform.hpp>

#include <vector>

enum Camera_Movement {
    FORWARD,  //前
    BACKWARD, //后
    LEFT,     //左
    RIGHT,    //右
    UPWARD,   //上
    DOWN      //下
};

//默认Camera默认
const float YAW         = -90.f; //偏航角
const float PITCH       = 0.0f;  //俯仰角
const float SPEED       = 2.5;   //camera移动速度
const float SENSITIVITY = 0.1f;  //鼠标灵敏度
const float ZOOM        = 45.0f; //视野


//一个抽象的相机类，用于处理输入并计算相应的欧拉角、向量和矩阵，供OpenGL使用
class Camera
{
public:
    // 相机属性
    glm::vec3 Position;  //相机位置
    glm::vec3 Front;     //相机方向向量
    glm::vec3 Up;        //相机上轴
    glm::vec3 Right;     //相机右轴
    glm::vec3 WorldUp;   //世界向上的向量
    // 欧拉角
    float Yaw;
    float Pitch;
    // 相机的选择
    float MovementSpeed;
    float MouseSensitivity;
    float Zoom;
    
    
    //带向量的构造函数
    Camera(glm::vec3 position = glm::vec3(0.0f,0.0f,0.0f),
           glm::vec3 up       = glm::vec3(0.0f,1.0f,0.0f),
           float yaw = YAW,float pitch = PITCH)
    : Front(glm::vec3(0.0f,0.0f,-1.0f)),
      MovementSpeed(SPEED),
      MouseSensitivity(SENSITIVITY),
      Zoom(ZOOM)
    {
        Position = position;
        WorldUp = up;
        Yaw = yaw;
        Pitch = pitch;
        updateCameraVectors();
    }
    
    // 带有标量值的构造函数
    Camera(float posX, float posY, float posZ,
           float upX, float upY, float upZ,
           float yaw, float pitch)
     : Front(glm::vec3(0.0f, 0.0f, -1.0f)),
       MovementSpeed(SPEED),
       MouseSensitivity(SENSITIVITY),
       Zoom(ZOOM)
    {
        Position = glm::vec3(posX, posY, posZ);
        WorldUp = glm::vec3(upX, upY, upZ);
        Yaw = yaw;
        Pitch = pitch;
        updateCameraVectors();
    }
    //返回使用欧拉角和LookAt矩阵计算的视图矩阵
    glm::mat4 GetViewMatrix()
    {
        return glm::lookAt(Position, Position + Front, Up);
    }
    
    
private:
    //计算摄像机位置 求一个3D空间一个点的坐标
    void updateCameraVectors()
    {
        glm::vec3 front;
        front.y = sin(glm::radians(Pitch));
        
        front.x = cos(glm::radians(Pitch)) * cos(glm::radians(Yaw));
        front.z = cos(glm::radians(Pitch)) * sin(glm::radians(Yaw));
        
        Front = glm::normalize(front);//方向向量
        //也重新计算右和向上向量 normalize归一化
        Right = glm::normalize(glm::cross(Front, WorldUp)); //相机右轴
        Up    = glm::normalize(glm::cross(Right, Front));   //相机上轴
    }
          
public:
    // 摄像机平移
    void ProcessKeyboard(Camera_Movement direction, float deltaTime)
    {
        float velocity = MovementSpeed * deltaTime;
        if (direction == FORWARD)
            Position += Front * velocity;
        if (direction == BACKWARD)
            Position -= Front * velocity;
        if (direction == LEFT)
            Position -= Right * velocity;
        if (direction == RIGHT)
            Position += Right * velocity;
        if (direction == UPWARD)
            Position += Up * velocity;
        if (direction == DOWN)
            Position -= Up * velocity;
    }

    // 摄像机旋转
    void ProcessMouseMovement(float xoffset, float yoffset, GLboolean constrainPitch = true)
    {
        xoffset *= MouseSensitivity;
        yoffset *= MouseSensitivity;

        Yaw   += xoffset;
        Pitch += yoffset;

        // 确保当俯仰出界时，屏幕不会被翻转
        if (constrainPitch)
        {
            if (Pitch > 89.0f)
                Pitch = 89.0f;
            if (Pitch < -89.0f)
                Pitch = -89.0f;
        }
        updateCameraVectors();
    }

    //摄像机视野
    void ProcessMouseScroll(float yoffset)
    {
        Zoom -= (float)yoffset;
        if (Zoom < 1.0f)
            Zoom = 1.0f;
        if (Zoom > 45.0f)
            Zoom = 45.0f;
    }
    
};



#endif /* Camera_h */
