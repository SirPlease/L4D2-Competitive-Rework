#if defined _readyup_footer_included
 #endinput
#endif
#define _readyup_footer_included

#define MAX_FOOTER_LEN 65

methodmap Footer < ArrayList {
	public Footer() {
		return view_as<Footer>(new ArrayList(ByteCountToCells(MAX_FOOTER_LEN)));
	}
	
	/*public void Clear() { // use ArrayList.Clear()
		
	}*/
	
	public int Add(const char[] format, int c = 1) {
		char buffer[MAX_FOOTER_LEN];
		FormatEx(buffer, sizeof(buffer), format, c);
		if (!IsEmptyString(buffer, sizeof(buffer))) {
			return this.PushString(buffer);
		}
		
		return -1;
	}
	
	public bool Edit(int index, const char[] str) {
		if (this.Length > index) {
			this.SetString(index, str);
			return true;
		}
		
		return false;
	}
	
	public int Find(const char[] str) {
		return this.FindString(str);
	}
	
	public char[] Get(int index) {
		static char buffer[MAX_FOOTER_LEN];
		if (this.Length > index) {
			this.GetString(index, buffer, sizeof(buffer));
			return buffer;
		} else {
			buffer[0] = '\0';
		}
		
		return buffer;
	}
}