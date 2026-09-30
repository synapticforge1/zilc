#include <stdio.h>
#include <string.h>
#include <stdlib.h>

static void tmpl_render(const char *tmpl, const char *value) {
    const char *dot = strstr(tmpl, "{{.}}");
    if (!dot) { printf("%s", tmpl); return; }
    int prefix = (int)(dot - tmpl);
    printf("%.*s%s%s", prefix, tmpl, value, dot + 5);
}

static void tmpl_if(const char *value) {
    if (value && value[0] != '\0') printf("yes \n");
    else printf("no \n");
}

static void tmpl_range(const char **items, int n) {
    printf("Range: ");
    for (int i = 0; i < n; i++) printf("%s ", items[i]);
    printf("\n");
}

int main(void) {
    tmpl_render("Value: {{.}}\n", "some text");
    tmpl_render("Value: {{.}}\n", "5");

    char arr_str[64] = "[";
    const char *langs[] = {"Go", "Rust", "C++", "C#"};
    int n = 4;
    for (int i = 0; i < n; i++) {
        strcat(arr_str, langs[i]);
        if (i < n - 1) strcat(arr_str, " ");
    }
    strcat(arr_str, "]");
    tmpl_render("Value: {{.}}\n", arr_str);

    tmpl_render("Name: {{.}}\n", "Jane Doe");
    tmpl_render("Name: {{.}}\n", "Mickey Mouse");

    tmpl_if("not empty");
    tmpl_if("");

    tmpl_range(langs, n);

    return 0;
}
