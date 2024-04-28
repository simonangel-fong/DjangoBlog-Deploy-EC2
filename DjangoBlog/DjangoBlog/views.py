from django.views.generic.base import TemplateView


# View of home page
class HomeView(TemplateView):
    template_name = "index.html"     # the template of this view
    extra_context = {'title': "DjangoBlog Home"}
