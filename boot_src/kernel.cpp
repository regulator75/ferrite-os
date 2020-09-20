//
// Switching to CPP to figure out how to invoke these bad boys
//


class CppLibTesterClazz{
public:
	CppLibTesterClazz(int x): m_x(x) {}
private:
	int m_x;

};
volatile CppLibTesterClazz * p_instance;


void kernel_cpp_entry() {
	p_instance = new CppLibTesterClazz(42);

}

extern "C" void kernel_c_entry(void) {

}