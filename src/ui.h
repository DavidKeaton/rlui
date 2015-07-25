#ifndef  UI_INC
#define  UI_INC

#include "enums.h"

#include <ncurses.h>

#include <tuple>
#include <memory>


// window class to handle mem for ncurses WINDOW
class window
{
	private:
		WINDOW *win = nullptr;
		int width, height, x, y;
        /* should the window be drawn? */
        bool hidden = false;
        /* if the current window is valid in its current form */
		bool valid = false;
        /* if the window is ready to be refreshed (has been updated) */
        bool ready = false;

		/* starts up the window */
		bool init(void);
		/* makes sure everything is closed down properly */
		void shutdown(void);
	public:
		window(int w, int h, int x, int y);
		~window(void);

// properties
        /* is the window valid and able to be used? */
        bool is_valid(void) const
            {return valid;}
        /* is the window ready to be updated? */
        bool is_ready(void) const 
            {return ready;}
        /* is the window hidden? */
        bool is_hidden(void) const 
            {return hidden;}
        /* return the size back into the given vars */
		void get_size(int &w, int &h) const;
        /* return the position back into the given vars */
		void get_pos(int &x, int &y) const;
        /* return tuple describing size */
		const std::pair<int, int> get_size(void) const;
        /* return tuple describing position */
		const std::pair<int, int> get_pos(void) const;

// modify attributes
        /* returns true if able to set, false otherwise */
		virtual bool set_size(int w, int h);
        /* returns true if able to set, false otherwise */
		virtual bool set_pos(int x, int y);

// updating window
        /* prepare the window for a refresh
         * need to `refresh()' to finalize */
        void update(void);
        /* finalize the window draw with new content
         * calls `update()' if not done so yet */
		void refresh(void);
		void show(void)
            {hidden = true;}
		void hide(void)
            {hidden = false;}
};

// base for all styles of ui, provides the basics for each type
class ui_base
{
    protected:
        /* specialized curses window */
		std::unique_ptr<window> win;
        /* synchronize the internals with what is displayed */
        virtual void sync(void);
	public:
        /* redraw the element */
        virtual void refresh(void);
};






#endif   /* ----- #ifndef UI_INC  ----- */
