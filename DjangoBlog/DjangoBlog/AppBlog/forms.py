from django import forms
from .models import Blog, Hashtag


class BlogForm(forms.ModelForm):
    ''' The form to submit a post '''
    class Meta:
        model = Blog
        fields = ("title", "content", "hashtags")
        # set widgets for fields
        widgets = {
            "title": forms.TextInput(attrs={"class": "form-control"}),
            "content": forms.Textarea(attrs={"class": "form-control editor", "rows": "3"}),
            "hashtags": forms.CheckboxSelectMultiple(attrs={"class": "form-check-input"})
        }
