#include <linux/module.h>
#include <linux/vermagic.h>
#include <linux/compiler.h>

MODULE_INFO(vermagic, VERMAGIC_STRING);

struct module __this_module
__attribute__((section(".gnu.linkonce.this_module"))) = {
 .name = KBUILD_MODNAME,
 .init = init_module,
#ifdef CONFIG_MODULE_UNLOAD
 .exit = cleanup_module,
#endif
 .arch = MODULE_ARCH_INIT,
};

static const struct modversion_info ____versions[]
__used
__attribute__((section("__versions"))) = {
	{ 0x96d03e4a, "struct_module" },
	{ 0xdc1198dd, "usb_register_driver" },
	{ 0xb4155661, "usb_register_dev" },
	{ 0x12da5bb2, "__kmalloc" },
	{ 0xc03d97e8, "usb_get_dev" },
	{ 0x83800bfa, "kref_init" },
	{ 0xfc993c2a, "kmem_cache_alloc" },
	{ 0x5f18459, "kmalloc_caches" },
	{ 0x37a0cba, "kfree" },
	{ 0x846049b6, "usb_put_dev" },
	{ 0x2f287f0d, "copy_to_user" },
	{ 0xfe6884a6, "usb_bulk_msg" },
	{ 0x8c604cf7, "usb_submit_urb" },
	{ 0x4256093f, "usb_free_urb" },
	{ 0xfb4f5f6c, "usb_buffer_free" },
	{ 0xd6c963c, "copy_from_user" },
	{ 0x7e2a4dac, "usb_buffer_alloc" },
	{ 0x9a66c746, "usb_alloc_urb" },
	{ 0x9775cdc, "kref_get" },
	{ 0x6c782f84, "usb_find_interface" },
	{ 0xb72397d5, "printk" },
	{ 0xb1f975aa, "unlock_kernel" },
	{ 0x6a30a276, "usb_deregister_dev" },
	{ 0x3656bf5a, "lock_kernel" },
	{ 0xd5b037e1, "kref_put" },
	{ 0xde6f3e75, "usb_deregister" },
	{ 0xb4390f9a, "mcount" },
};

static const char __module_depends[]
__used
__attribute__((section(".modinfo"))) =
"depends=usbcore";

MODULE_ALIAS("usb:v03EBp6124d*dc*dsc*dp*ic*isc*ip*");

MODULE_INFO(srcversion, "4D0DE062E25B5C9FF33B30E");
