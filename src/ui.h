#ifndef  UI_INC
#define  UI_INC

#include "enums.h"
#include "ui_event.h"

#include <ncurses.h>

#include <tuple>
#include <memory>
#include <string>
#include <vector>
#include <functional>
#include <map>
#include <list>
#include <queue>


/* used for ui callbacks */
class ui_base;
typedef std::function<void(const ui_base *ui, void *ptr)> ui_callback;

/* template for custom routines passed to `ui_base' */
typedef std::function<int(const ui_event &event, void *userdata)> ui_function;

/* error codes for the ui */
enum ui_errno {
    UI_EFATAL = 0,
    UI_EFILE,
    UI_EBADARG,
    NUM_ERRNO
};

/* error info struct */
struct ui_error {
    /* error code, from above enum */
    const ui_errno errno;
    /* error message text */
    const std::string msg;
};

// TODO: add static pairing of error code + error message
// TODO: (probably in a TU)

/*** class: window {{{1
 * Specialized class to handle details and memory for curses windows
 ***/
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
        window();
		window(int w, int h, int x, int y);
		~window();

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
}; // }}}1
/*** class: ui_base {{{1
 * Base virtual class for ui elements and ui core classes alike.
 ***/
class ui_base
{
    private:
        /* the queue of events, as the name implies */
        std::queue<ui_event> events;
        /* userdata associated to specific `ui_event_type's */
        std::map<ui_event_type, void*> userdata;
    protected:
        /* specialized curses window */
		std::unique_ptr<window> win;
// events handling
        /* handle processing events and adding them to the queue */
        void process_events(void);
        /* see the next event, without removing it */
        const ui_event &peek_event(void);
// display
        /* synchronize the internals with what is displayed 
         * this is where you gather the data and format it
         * to be displayed by refresh */
        virtual void sync(void);
        /* the `main()' of the ui element, handles the internals of
         * the ui class, preparing it for the next ui_function call */
        virtual int run(const ui_function &func);
	public:
        ui_base();
        /* explicitly declare window attributes */
        ui_base(int w, int h, int x, int y);
        virtual ~ui_base();

        /* invoke the ui element to execute its standard routine */
        virtual int operator()(const ui_function &func);
        /* redraw the element */
        virtual void refresh(void);
        /* set the userdata for the type of event */
        void set_userdata(const ui_event_type type, void *userdata)
            {this->userdata[type] = userdata;}
}; // }}}1
/*** class: ui_text {{{1
 * Class used to store information about any text for an ui
 * element. Also includes a way to prettify the text as well.
 ***/
class ui_text
{
    private:
        /* the text to display */
        std::string text;
        /* the text above, but formatted totes cute like 
         * each entry in the vector is its own line */
        std::vector<std::string> pretty_text;

        void init(void);
    protected:
        /* prettify the text stored in `text', 
         * and store in `pretty_text' */
        virtual void prettify(void);
    public:
        ui_text();
        ui_text(const std::string &S) :
            text(S) {init();};
        virtual ~ui_text();

        /* set the text of the dialog */
        virtual void set_text(const std::string &text);
        /* get the text stored */
        const std::string &get_text(void) const
            {return text;}
        /* get the prettified text */
        const std::vector<std::string> &get_pretty_text(void) const
            {return pretty_text;}
        /* clear the text stored */
        virtual void clear_text(void);
}; // }}}1
/*** class: ui_button {{{1
 * Creates a button for use within another element.
 ***/
class ui_button : public ui_base, public ui_text
{
    public:
        /* callback to execute when button is selected 
         * convenience for adding callback to event */
        void on_click(const ui_callback &func);
}; // }}}1
/*** class: ui_dialog {{{1
 * Displays a dialog box, with selected options on the bottom.
 * There doesn't need to be any at all, in which case this is
 * treated no different than a "dismiss on any key" dialog.
 * This dialog is centered on the screen, unless otherwise told.
 ***/
class ui_dialog : public ui_base, public ui_text
{
};




#endif   /* ----- #ifndef UI_INC  ----- */
