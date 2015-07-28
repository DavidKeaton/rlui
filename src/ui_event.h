#ifndef  UI_EVENT_INC
#define  UI_EVENT_INC

#include "enums.h"

#include <vector>


/* event types that can invoke a callback */
enum ui_event_type {
    UI_ON_ERROR = -1,
    UI_ON_EXIT  =  0,
    UI_ON_MOUSE,
    UI_ON_KEYBOARD,
    NUM_EVENTS
};

struct ui_event_exit {
    // how did the ui element finish?
    void *how = nullptr;
    // what to do on exit
    void *what = nullptr; // TODO: integrate this into the destructor
};

// as it says
enum ui_mouse_button {
    UI_MOUSE_NONE = 0,
    UI_MOUSE_LEFT,
    UI_MOUSE_MIDDLE,
    UI_MOUSE_RIGHT,
    UI_MOUSE_EXTRA,     // extra mouse keys
    NUM_MOUSE_BUTTONS
};

struct ui_event_mouse {
    // where the mouse was clicked
    point pos;
    // modifier keys
    std::vector<int> mods;
    // which mouse button was pressed
    ui_mouse_button button;
    // which extra mouse key was pressed if `UI_MOUSE_EXTRA'
    int extra;
};

struct ui_event_keyboard {
    // whether the keys are prefixed with `
    bool multichar;
    // modifier keys
    std::vector<int> mods;
    // what keys were pressed
    std::vector<int> keys;
};

/* stores information about the event */
struct ui_event {
    // determines the type of event this is
    ui_event_type type;
    // accessing the union depends on `type' of event
//    union {
        ui_event_mouse      on_mouse;
        ui_event_keyboard   on_keyboard;
//    } event;
    ui_event(ui_event_type T) : type(T) {};
};


#endif   /* ----- #ifndef UI_EVENT_INC  ----- */
