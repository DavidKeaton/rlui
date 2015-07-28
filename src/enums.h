#ifndef  ENUMS_INC
#define  ENUMS_INC

#include <tuple>

template <typename T>
struct coords {
    private:
        void assign(T x=0, T y=0, T z=0)
        {
            this->x = x;
            this->y = y;
            this->z = z;
        }
    public:
        T x, y, z;

        coords() {assign();}
        coords(T X, T Y) :
            x(X), y(Y) {};
        coords(T X, T Y, T Z) :
            x(X), y(Y), z(Z) {};
        coords(const std::pair<T, T> &rhs)
        {
            assign(rhs.first, rhs.second);
        }
        coords(const std::tuple<T, T, T> &rhs)
        {
            assign(std::get<0>(rhs), std::get<1>(rhs), std::get<2>(rhs));
        }
};

typedef struct coords<unsigned int> upoint;
typedef struct coords<int>          point;




#endif   /* ----- #ifndef ENUMS_INC  ----- */
